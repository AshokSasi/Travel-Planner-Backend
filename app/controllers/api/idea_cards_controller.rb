class Api::IdeaCardsController < ApplicationController
    before_action :set_idea_card, only: [:update, :destroy]
        before_action :set_trip, only: [:index, :create]
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def index
        render json: @trip.idea_cards
    end

    def create
        card = @trip.idea_cards.create!(idea_card_params)
        ItineraryItem.create!(title: card.title, notes: card.content, idea_card_id: card.id)
        render json: card
    end

    def update
        @idea_card.update!(idea_card_params)
        # Update the corresponding ItineraryItem if it exists
        itinerary_item = @idea_card.itinerary_items.first
        if itinerary_item
            itinerary_item.update!(title: @idea_card.title, notes: @idea_card.content)
        end
        render json: @idea_card
    end

    def destroy
        @idea_card.destroy
        render json: { message: "Idea card deleted successfully" }
    end

    private

    def invalid_create(error)
        render json: {message: error.message}, status: :unprocessable_entity
    end
    
    def render_not_found(error)
    render json: {message: error.message}, status: :not_found
    end

    def set_idea_card
        @idea_card = IdeaCard.find(params[:id])
    end

    def set_trip
        @trip = Trip.find(params[:trip_id])
    end

    def idea_card_params
        params.require(:idea_card).permit(:title, :content, :x, :y, :category, :upvotes, :image, :url)
    end
end
