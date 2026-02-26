class Api::TripsController < ApplicationController
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    before_action :authorize_request

    def index
        trips = current_user.trips.includes(trip_members: :user)
        render json: trips.as_json(include: { trip_members: { only: [:id, :user_id, :role], include: { user: { only: [:name] } } } })
    end
    
    def show
        @trip = Trip.includes(trip_members: :user).find(params[:id])
        render json: @trip.as_json(include: { trip_members: { only: [:id, :user_id, :role], include: { user: { only: [:name] } } } })
    end

    def create 
        trip = nil
        ActiveRecord::Base.transaction do
            trip = Trip.create!(trip_params)
            trip.trip_members.create!(user_id: current_user.id, trip_id: trip.id, role: "owner")
        end

        render json: trip, status: :created
        rescue ActiveRecord::RecordInvalid => e
            render json: { error: e.message }, status: :unprocessable_entity

    end

    def join
        trip = Trip.find_by!(invite_token: params[:invite_token])

        if trip.nil?
            return render json: { error: 'Invalid invite token' }, status: :not_found
        end

        if trip.invite_expires_at.present? && trip.invite_expires_at < Time.current
            return render json: { error: 'Invite token has expired' }, status: :forbidden
        end
        membership = TripMember.find_or_create_by(user_id: current_user.id, trip_id: trip.id) do |tm|
            tm.role = "editor"
        end
        render json: {trip: trip, membership: membership }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Invalid invite token' }, status: :not_found
    end

    def send_join_email
        trip = Trip.find(params[:id])
        TripMailer.with(email: params[:email], trip: trip, url: "#{ENV['FRONTEND_URL']}/login?inviteToken=#{trip.invite_token}&tripId=#{trip.id}").invite_email.deliver_now
        render json: { message: 'Join email sent' }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
    end

    def regenerate_invite
        trip = current_user.trips.find(params[:id])
        trip.update!(invite_token: SecureRandom.urlsafe_base64(16), invite_expires_at: 7.days.from_now)
        render json: {invite_token: trip.invite_token, invite_expires_at: trip.invite_expires_at }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
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
