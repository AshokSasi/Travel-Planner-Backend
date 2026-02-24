class Api::TripsController < ApplicationController
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def index
        trips = Trip.all
        render  json:trips
    end
    
    def show
        @trip = Trip.find(params[:id])
        render json:@trip
    end

    def create 
        trip = Trip.create!(trip_params)
        render json: trip
    end

    private
    def trip_params
        params.require(:trip).permit(:name, :location, :start_date, :end_date)
    end

    def invalid_create(error)
        render json: {message: error.message}, status: :unprocessable_entity
    end

    def render_not_found(error)
        render json: {message: error.message}, status: :not_found
    end
end
