class Api::CategoriesController < ApplicationController
    before_action :set_category, only: [:update, :destroy]
    before_action :set_trip, only: [:index, :create, :update, :destroy]
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def create
        @category = @trip.categories.create!(category_params)
        ActionCable.server.broadcast("trip_#{@trip.id}", { type: "CATEGORY_CREATED", item: @category })
        render json: @category
    end

    def index
        categories = @trip.categories
        render json: categories
    end

    def update
        @category.update!(category_params)
        ActionCable.server.broadcast("trip_#{@trip.id}", { type: "CATEGORY_UPDATED", item: @category })
        render json: @category
    end

    def destroy
        @category.destroy!
        ActionCable.server.broadcast("trip_#{@trip.id}", { type: "CATEGORY_DELETED", item_id: @category.id.to_s })
        head :no_content
    end

    private

    def invalid_create(error)
        render json: {message: error.message}, status: :unprocessable_entity
    end
    
    def render_not_found(error)
        render json: {message: error.message}, status: :not_found
    end

    def set_category
        @category = Category.find(params[:id])
    end

    def set_trip
        @trip = Trip.find(params[:trip_id])
    end

    def category_params
        params.permit(:name, :color, :x, :y, :width, :height)
    end
end
