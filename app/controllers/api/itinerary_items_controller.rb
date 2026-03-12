class Api::ItineraryItemsController < ApplicationController
    before_action :set_itinerary_item, only: [:update]
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def index
        trip = Trip.find(params[:trip_id])
        items = ItineraryItem.joins(:idea_card).where(idea_cards: { trip_id: trip.id })
        render json: items.as_json(include: { idea_card: { only: [:title, :content, :category, :url, :image] } })
    end

    def create
        trip = Trip.find(params[:trip_id])
        idea_card = trip.idea_cards.create!(title: params[:itinerary_item][:title])
        card = ItineraryItem.create!(itinerary_item_params.merge(idea_card_id: idea_card.id))
        ActionCable.server.broadcast(
          "trip_#{trip.id}",
          { type: "ITINERARY_CREATED", items: card.as_json }
        )
        render json: card
    end

    def update
        @itinerary_item.update!(itinerary_item_params)
         ActionCable.server.broadcast(
      "trip_#{@itinerary_item.idea_card.trip_id}",
      { type: "ITINERARY_UPDATED", item: @itinerary_item.as_json }
    )
        render json: @itinerary_item
    end

    # def destroy
    #     @idea_card.destroy
    #     render json: { message: "Idea card deleted successfully" }
    # end

    private

    def invalid_create(error)
        render json: {message: error.message}, status: :unprocessable_entity
    end
    
    def render_not_found(error)
    render json: {message: error.message}, status: :not_found
    end

    def set_itinerary_item
        @itinerary_item = ItineraryItem.find(params[:id])
    end

    def itinerary_item_params
        params.require(:itinerary_item).permit(:title, :notes, :itinerary_day_id, :scheduled_time, :time_of_day, :address)
    end
end
