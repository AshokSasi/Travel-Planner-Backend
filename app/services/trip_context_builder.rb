# Plain-text snapshot of everything the trip assistant should know, rebuilt from the
# database on every message so it reflects edits made by other members between turns
class TripContextBuilder
    MAX_IDEAS = 50

    def initialize(trip, user, today: Date.current)
        @trip = trip
        @user = user
        @today = today
    end

    def call
        [
            trip_section,
            group_section,
            preferences_section,
            itinerary_section,
            ideas_section
        ].join("\n\n")
    end

    private

    def trip_section
        num_days = (@trip.end_date - @trip.start_date).to_i + 1
        <<~TEXT.strip
        ## Trip
        Name: #{@trip.name}
        Destination: #{@trip.location}
        Dates: #{format_date(@trip.start_date)} to #{format_date(@trip.end_date)} (#{num_days} days)
        Today: #{format_date(@today)} (#{timing})
        TEXT
    end

    def timing
        if @today < @trip.start_date
            "trip starts in #{(@trip.start_date - @today).to_i} days"
        elsif @today > @trip.end_date
            "trip has ended"
        else
            "trip in progress, today is day #{(@today - @trip.start_date).to_i + 1}"
        end
    end

    def group_section
        members = @trip.trip_members.includes(:user).map { |m| "#{m.user.name} (#{m.role})" }
        asking = @trip.trip_members.find_by(user: @user)
        <<~TEXT.strip
        ## Group
        #{members.size} travellers: #{members.join(', ')}
        Asking now: #{@user.name}#{" (#{asking.role})" if asking}
        TEXT
    end

    def preferences_section
        prefs = (@trip.preferences || {}).with_indifferent_access
        if prefs.blank?
            return "## Preferences\nNot saved for this trip. Infer budget and style from the itinerary " \
                   "(e.g. the accommodation level) and don't ask the user to restate them."
        end

        lines = {
            "Budget" => prefs[:budget],
            "Travel style" => prefs[:travel_style],
            "Group type" => prefs[:group_type],
            "Interests" => Array(prefs[:interests]).join(", ").presence,
            "Pace" => prefs[:pace],
            "Focus regions" => Array(prefs[:regions]).join(", ").presence,
            "Notes" => prefs[:notes]
        }.compact_blank.map { |label, value| "#{label}: #{value}" }

        Array(prefs[:answers]).each do |a|
            next if a[:answer].blank?
            lines << "Q: #{a[:question]} A: #{Array(a[:answer]).join(', ')}"
        end

        "## Preferences (given when the itinerary was generated)\n#{lines.join("\n")}"
    end

    def itinerary_section
        days = @trip.itinerary_days.includes(:itinerary_items).order(:day_number)
        body = days.map { |day| format_day(day) }.join("\n")
        "## Itinerary (ids are what you reference in changes)\n#{body}"
    end

    def format_day(day)
        header = "Day #{day.day_number} · #{format_date(day.date)}"
        header += " · #{day.city}" if day.city.present?
        if day.accomodation_name.present?
            header += " · Stay: #{day.accomodation_name}"
            header += " (#{day.accomodation_address})" if day.accomodation_address.present?
        end

        items = sorted_items(day)
        return "#{header}\n  (nothing planned)" if items.empty?

        lines = items.map do |item|
            time = item.scheduled_time&.strftime("%H:%M") || "no time"
            line = "  - [item #{item.id}] #{time} #{item.time_of_day} · #{item.title}"
            line += " @ #{item.address}" if item.address.present?
            line += " · #{item.notes}" if item.notes.present?
            line
        end
        "#{header}\n#{lines.join("\n")}"
    end

    def sorted_items(day)
        day.itinerary_items.sort_by { |i| [ i.scheduled_time ? 0 : 1, i.scheduled_time.to_s, i.order_index.to_i ] }
    end

    def ideas_section
        scheduled_ids = ItineraryItem.joins(:itinerary_day)
                                     .where(itinerary_days: { trip_id: @trip.id })
                                     .pluck(:idea_card_id)
        ideas = @trip.idea_cards.where.not(id: scheduled_ids)
                     .left_joins(:idea_upvotes).group(:id)
                     .select("idea_cards.*, COUNT(idea_upvotes.id) AS votes")
                     .order(Arel.sql("votes DESC")).limit(MAX_IDEAS).to_a
        return "## Saved ideas not yet in the itinerary\nnone" if ideas.empty?

        lines = ideas.map do |card|
            line = "  - [idea #{card.id}] #{card.title}"
            line += " (#{card.address})" if card.address.present?
            line += ", #{card.category}" if card.category.present?
            line + ", #{card.votes} upvotes"
        end
        "## Saved ideas not yet in the itinerary (most upvoted first)\n#{lines.join("\n")}"
    end

    def format_date(date)
        date.strftime("%a %b %-d, %Y")
    end
end
