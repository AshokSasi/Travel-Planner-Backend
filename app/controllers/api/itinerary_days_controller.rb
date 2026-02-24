class Api::ItineraryDaysController < ApplicationController
  before_action :set_trip

  def index
    render json: @trip.itinerary_days
  end

  def create
    # Auto-fill date: next day after latest, or today if none
    date = if params[:itinerary_day] && params[:itinerary_day][:date].present?
      params[:itinerary_day][:date]
    else
      last_day = @trip.itinerary_days.order(date: :desc).first
      last_day ? last_day.date + 1.day : Date.today
    end
    day = @trip.itinerary_days.create!(day_params.merge(date: date))
    update_trip_dates
    render json: day
  end

  def destroy
    @itinerary_day = ItineraryDay.find(params[:id])

    @itinerary_day.itinerary_items.update_all(itinerary_day_id: nil)
    @itinerary_day.destroy
    update_trip_dates
    render json: { message: "Itinerary day deleted successfully" }
   
  end

   def update_trip_dates
      days = @trip.itinerary_days.order(:date)
      if days.exists?
        @trip.update(start_date: days.first.date, end_date: days.last.date)
      else
        # Optionally, set to nil or keep previous values if no days exist
        @trip.update(start_date: nil, end_date: nil)
      end
    end

  private
  def day_params
    params.require(:itinerary_day).permit(:date)
  end
  def set_trip
    @trip = Trip.find(params[:trip_id])
  end
end
