class TripChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
     trip = Trip.find(params[:trip_id])
     stream_from "trip_#{trip.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
