class TripChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
     trip = Trip.find(params[:trip_id])
     stream_from "trip_#{trip.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def cursor_move(data)
    ActionCable.server.broadcast(
      "trip_#{params[:trip_id]}",
      {
        type: "CURSOR_MOVED",
        user_id: current_user.id.to_s,
        user_name: current_user.name,
        avatar_url: current_user.avatar_url,
        x: data["x"],
        y: data["y"]
      }
    )
  end

end
