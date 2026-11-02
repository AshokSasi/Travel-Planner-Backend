class ItineraryGeneratorService
    class TruncatedResponseError < StandardError; end

    # Non-streaming requests are capped by the SDK at ~21k tokens, so we stream
    MAX_TOKENS = 32_000

    def initialize(trip, preferences)
        @trip = trip
        @preferences = preferences
        @num_days = (trip.end_date - trip.start_date).to_i + 1
    end

    def call
        client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

        response = client.messages.stream(
            model: ENV.fetch("ITINERARY_MODEL", "claude-haiku-4-5-20251001"),
            max_tokens: MAX_TOKENS,
            messages: [ { role: "user", content: prompt } ]
        ).accumulated_message

        raw = response.content.select { |block| block.type == :text }.map(&:text).join
        if response.stop_reason == :max_tokens
            log_raw_reply(response.stop_reason, raw)
            raise TruncatedResponseError, "Itinerary was too long to generate in one go"
        end

        text = raw.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
        begin
            result = JSON.parse(text)
        rescue JSON::ParserError
            log_raw_reply(response.stop_reason, raw)
            raise
        end
        create_itinerary(result)
    end

    private

    def prompt
        <<~PROMPT
        Generate a detailed travel itinerary for this trip:
        Destination: #{@trip.location}
        Focus regions: #{format_regions}
        Start Date: #{@trip.start_date}
        End Date: #{@trip.end_date}
        Number of Days: #{@num_days}
        Travel month: #{@trip.start_date.strftime('%B')}
        Group size: #{@trip.trip_members.count}
        Budget: #{@preferences[:budget]}
        Travel style: #{@preferences[:travel_style]}
        Group type: #{@preferences[:group_type]}
        Interests: #{format_interests}
        Pace: #{@preferences[:pace].presence || "Balanced"}

        Traveller preferences (these override the generic rules below):
        Notes: #{@preferences[:notes].presence || "none"}
        #{format_answers}

        Ideas the group has already saved (most upvoted first):
        #{format_ideas}

        Return ONLY a valid JSON object, no other text, no markdown, no backticks:
      {
        "days": [
          {
            "day_number": 1,
            "date": "YYYY-MM-DD",
            "city": "City name",
            "accommodation_name": "Hotel name",
            "accommodation_address": "Full address",
            "items": [
              {
                "title": "Activity name",
                "notes": "Brief description and tips",
                "scheduled_time": "HH:MM:SS",
                "time_of_day": "morning",
                "order_index": 0,
                "address": "Full street address, City, Country",
                "idea_card_id": null
              }
            ]
          }
        ]
      }

      Rules:
      - Budget is a hard constraint for accommodation, dining and paid activities: #{budget_guidance}
      - Prefer staying in the same accommodation for consecutive days in the same city
      - time_of_day must be one of: morning, afternoon, evening
      - scheduled_time must be in HH:MM:SS format
      - Keep notes to 1-2 short sentences
      - Generate 3-5 items per day (2-3 if pace is Relaxed, 5-6 if pace is Packed)
      - If focus regions are given, only plan within those regions. Include realistic travel time between regions
        (e.g. a travel day or domestic flight for long distances) and don't zig-zag between them
      - Prioritise the group's saved ideas, especially highly upvoted ones, where they fit geographically.
        When an item is one of those ideas, set idea_card_id to its id; otherwise set idea_card_id to null
      - Be specific with real place names and addresses
      - address must be a real, specific street address suitable for Google Maps search
      - If a specific street address is unknown, use the place name and city (e.g. "Eiffel Tower, Paris, France")
      - If interests include Food & Nightlife, include at least one restaurant or bar per day
      - If interests include Nature & Outdoors, avoid scheduling indoor activities in the morning
      - If no interests specified, generate a balanced mix of everything
      - Work out the season from the travel month and the destination's hemisphere (e.g. December is summer in Patagonia),
        and factor it in (e.g. winter = indoor alternatives, skiing, holiday events; summer = outdoor, beaches, festivals)
    PROMPT
    end

    def log_raw_reply(stop_reason, raw)
        Rails.logger.error(
            "[ItineraryGenerator] trip=#{@trip.id} stop_reason=#{stop_reason} length=#{raw.length} " \
            "head=#{raw[0, 300].inspect} tail=#{raw[-300..]&.inspect || raw.inspect}"
        )
    end

    LUXURY_BRANDS = "Ritz-Carlton, Four Seasons, Aman, Mandarin Oriental, Peninsula, Park Hyatt, St. Regis, Waldorf Astoria".freeze

    def budget_guidance
        case @preferences[:budget].to_s.downcase
        when /budget|low|cheap|backpack/
            "hostels, guesthouses, capsule or simple business hotels (roughly under $80/night); street food, markets and casual eateries; " \
            "mostly free or cheap sights. Never suggest luxury or upscale hotels."
        when /luxury|high|premium/
            "5-star and boutique luxury hotels are fine; fine dining is welcome."
        else
            "mid-range 3-4 star hotels, well-reviewed local chains or ryokan/guesthouses (roughly $100-200/night per room); " \
            "casual to mid-range restaurants with at most an occasional nicer meal. " \
            "Never suggest luxury hotels such as #{LUXURY_BRANDS}."
        end
    end

    def format_interests
        return "Balanced mix of everything" if @preferences[:interests].blank?
        @preferences[:interests].join(", ")
    end

    def format_regions
        return "none, choose the best areas for the trip length" if @preferences[:regions].blank?
        @preferences[:regions].join(", ")
    end

    def format_answers
        answers = Array(@preferences[:answers]).select { |a| a[:answer].present? }
        return "" if answers.empty?
        answers.map { |a| "Q: #{a[:question]}\nA: #{Array(a[:answer]).join(', ')}" }.join("\n")
    end

    def existing_ideas
        @existing_ideas ||= @trip.idea_cards.left_joins(:idea_upvotes).group(:id)
                                 .select("idea_cards.*, COUNT(idea_upvotes.id) AS votes")
                                 .order(Arel.sql("votes DESC")).limit(50).to_a
    end

    def format_ideas
        return "none" if existing_ideas.empty?
        existing_ideas.map { |card|
            "- id #{card.id}: #{card.title}#{" (#{card.address})" if card.address.present?}, #{card.votes} upvotes"
        }.join("\n")
    end

  CARD_COLUMN_WIDTH = 320
  CARD_ROW_HEIGHT = 180

  def create_itinerary(result)
    created_days = []

    result["days"].each_with_index do |day_data, day_index|
      day = @trip.itinerary_days.find_by(day_number: day_data["day_number"])
      next unless day

      day.update!(
        city: day_data["city"],
        accomodation_name: day_data["accommodation_name"],
        accomodation_address: day_data["accommodation_address"]
      )

      day.itinerary_items.destroy_all

      day_data["items"].each_with_index do |item, item_index|
        idea_card = existing_ideas.find { |card| card.id.to_s == item["idea_card_id"].to_s } if item["idea_card_id"].present?
        idea_card ||= @trip.idea_cards.create!(
          title: item["title"],
          content: item["notes"],
          x: day_index * CARD_COLUMN_WIDTH,
          y: item_index * CARD_ROW_HEIGHT
        )
        day.itinerary_items.create!(
          title: item["title"],
          notes: item["notes"],
          scheduled_time: item["scheduled_time"],
          time_of_day: item["time_of_day"],
          order_index: item["order_index"],
          address: item["address"],
          idea_card: idea_card
        )
      end

      created_days << day
    end

    created_days
  end
end
