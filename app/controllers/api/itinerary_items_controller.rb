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
        card = ItineraryItem.create!(itinerary_item_params)
        render json: card
    end

    def update
        @itinerary_item.update!(itinerary_item_params)
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
        params.require(:itinerary_item).permit(:title, :notes, :itinerary_day_id, :scheduled_time)
    end
end
