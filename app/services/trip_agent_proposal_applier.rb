# Applies the selected changes of a pending proposal in one transaction. If an item the
# proposal touches was edited or deleted since it was made, nothing is applied and the
# proposal is marked stale.
class TripAgentProposalApplier
    class StaleError < StandardError; end
    class InvalidError < StandardError; end

    def initialize(proposal, user, change_ids = nil)
        @proposal = proposal
        @trip = proposal.trip
        @user = user
        @change_ids = change_ids
        @created = []
        @updated = []
        @deleted_ids = []
    end

    def call
        raise InvalidError, "This proposal was already #{@proposal.status}" unless @proposal.pending?

        changes = selected_changes
        raise InvalidError, "No changes selected" if changes.empty?

        stale = false
        ActiveRecord::Base.transaction do
            @proposal.lock!
            raise InvalidError, "This proposal was already #{@proposal.status}" unless @proposal.pending?

            if stale?(changes)
                stale = true
                raise ActiveRecord::Rollback
            end

            changes.each { |change| apply(change) }
            renumber_days
            @proposal.resolve!("applied", @user, applied_change_ids: changes.map { |c| c["id"] })
        end

        if stale
            @proposal.resolve!("stale", @user)
            broadcast_proposal
            raise StaleError, "The itinerary changed since this was suggested"
        end

        broadcast
        @proposal
    end

    # Items created or edited by the last call, so the client can highlight them
    def touched_item_ids
        (@created + @updated).map { |item| item.id.to_s }
    end

    private

    def selected_changes
        return @proposal.changes_list if @change_ids.nil?
        ids = Array(@change_ids).map(&:to_s)
        @proposal.changes_list.select { |c| ids.include?(c["id"]) }
    end

    def days
        @days ||= @trip.itinerary_days.index_by(&:day_number)
    end

    def stale?(changes)
        changes.any? do |change|
            next true unless days.key?(change["day_number"])
            next false unless change["item_id"]

            item = find_item(change["item_id"])
            item.nil? || item.updated_at.iso8601(6) != change["item_updated_at"]
        end
    end

    def find_item(id)
        ItineraryItem.joins(:itinerary_day).where(itinerary_days: { trip_id: @trip.id }).find_by(id: id)
    end

    def apply(change)
        day = days.fetch(change["day_number"])
        after = change["after"] || {}

        case change["action"]
        when "add"
            add_item(day, after, change["idea_card_id"])
        when "update", "move"
            item = find_item(change["item_id"])
            attrs = after.slice("title", "notes", "address", "scheduled_time")
            attrs["time_of_day"] = nil if attrs.key?("scheduled_time") # recomputed from the time
            item.update!(attrs.merge("itinerary_day_id" => day.id))
            @updated << item
        when "remove"
            item = find_item(change["item_id"])
            item.destroy!
            @deleted_ids << item.id.to_s
        when "update_day"
            day.update!(
                city: after["city"] || day.city,
                accomodation_name: after["accommodation_name"] || day.accomodation_name,
                accomodation_address: after["accommodation_address"] || day.accomodation_address
            )
        end
    end

    def add_item(day, after, idea_card_id)
        idea_card = @trip.idea_cards.find_by(id: idea_card_id) if idea_card_id
        idea_card ||= @trip.idea_cards.create!(
            title: after["title"],
            content: after["notes"],
            address: after["address"],
            x: (day.day_number - 1) * ItineraryGeneratorService::CARD_COLUMN_WIDTH,
            y: day.itinerary_items.count * ItineraryGeneratorService::CARD_ROW_HEIGHT
        )
        @created << day.itinerary_items.create!(
            title: after["title"],
            notes: after["notes"],
            address: after["address"],
            scheduled_time: after["scheduled_time"],
            idea_card: idea_card
        )
    end

    # Keep order_index in time order on every day we touched
    def renumber_days
        touched = (@created + @updated).map(&:itinerary_day_id).uniq
        ItineraryDay.where(id: touched).includes(:itinerary_items).each do |day|
            sorted = day.itinerary_items.sort_by { |i| [ i.scheduled_time ? 0 : 1, i.scheduled_time.to_s, i.order_index.to_i ] }
            sorted.each_with_index { |item, index| item.update_columns(order_index: index) }
        end
    end

    def broadcast
        channel = "trip_#{@trip.id}"
        @created.each { |item| ActionCable.server.broadcast(channel, { type: "ITINERARY_CREATED", item: item.reload.as_json }) }
        @updated.each { |item| ActionCable.server.broadcast(channel, { type: "ITINERARY_UPDATED", item: item.reload.as_json }) }
        @deleted_ids.each { |id| ActionCable.server.broadcast(channel, { type: "ITINERARY_DELETED", item_id: id }) }
        broadcast_proposal
    end

    def broadcast_proposal
        ActionCable.server.broadcast("trip_#{@trip.id}", { type: "AGENT_PROPOSAL_UPDATED", item: @proposal.reload.as_json })
    end
end
