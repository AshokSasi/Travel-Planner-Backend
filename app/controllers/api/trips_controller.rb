class Api::TripsController < ApplicationController
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    before_action :authorize_request

    def index
        trips = current_user.trips.includes(trip_members: :user).where(is_template: false)
        render json: trips.as_json(include: { trip_members: { only: [:id, :user_id, :role], include: { user: { only: [:name], methods: [:avatar_url] } } } })
    end
    
    def show
        @trip = Trip.includes(trip_members: :user).find(params[:id])
        render json: @trip.as_json(include: { trip_members: { only: [:id, :user_id, :role], include: { user: { only: [:name], methods: [:avatar_url] } } } })
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

    def update
        trip = current_user.trips.find(params[:id])
        trip.update!(trip_params)
        render json: trip, status: :ok
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
        trip = current_user.trips.find(params[:id])
        trip.destroy
        render json: { message: 'Trip deleted' }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
    end
    
    def join
        trip = Trip.find_by!(invite_token: params[:invite_token])

        if trip.nil?
            return render json: { error: 'Invalid invite token' }, status: :not_found
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
        trip.update!(invite_token: SecureRandom.urlsafe_base64(16))
        render json: { invite_token: trip.invite_token }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
    end

    def leave_trip
        trip = current_user.trips.find(params[:id])
        membership = trip.trip_members.find_by(user_id: current_user.id)
        if membership
            membership.destroy
            render json: { message: 'Left the trip' }, status: :ok
        else
            render json: { error: 'Membership not found' }, status: :not_found
        end
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
    end

    def publish_template
        source = current_user.trips.find(params[:id])

        new_trip = nil
        ActiveRecord::Base.transaction do
            new_trip = Trip.create!(trip_params.merge(is_template: true, published_at: Time.current))
            new_trip.trip_members.create!(user_id: current_user.id, trip_id: new_trip.id, role: "owner")

            idea_card_id_map = {}
            source.idea_cards.each do |card|
                new_card = new_trip.idea_cards.create!(
                    title: card.title, content: card.content,
                    x: card.x, y: card.y, category: card.category,
                    url: card.url, image: card.image, upvotes: 0
                )
                idea_card_id_map[card.id] = new_card.id
            end

            day_number_map = new_trip.itinerary_days.index_by(&:day_number)

            source.itinerary_days.includes(:itinerary_items).each do |old_day|
                new_day = day_number_map[old_day.day_number]
                next unless new_day

                old_day.itinerary_items.each do |item|
                    new_idea_card_id = idea_card_id_map[item.idea_card_id]
                    next unless new_idea_card_id

                    new_day.itinerary_items.create!(
                        idea_card_id: new_idea_card_id,
                        title: item.title, notes: item.notes,
                        order_index: item.order_index,
                        scheduled_time: item.scheduled_time,
                        time_of_day: item.time_of_day
                    )
                end
            end
        end

        render json: new_trip, status: :created
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Trip not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    def get_templates
        templates = Trip.where(is_template: true).includes(trip_members: :user)
        render json: templates.map { |trip|
            owner = trip.trip_members.find { |tm| tm.role == 'owner' }&.user
            trip.as_json.merge(owner_name: owner&.name)
        }, status: :ok
    end

    def duplicate_template
        source = Trip.find(params[:id])
        return render json: { error: 'Trip is not a template' }, status: :unprocessable_entity unless source.is_template?

        new_trip = nil
        ActiveRecord::Base.transaction do
            new_trip = Trip.create!(trip_params.merge(is_template: false))
            new_trip.trip_members.create!(user_id: current_user.id, trip_id: new_trip.id, role: "owner")

            # Map old idea_card id -> new idea_card
            idea_card_id_map = {}
            source.idea_cards.each do |card|
                new_card = new_trip.idea_cards.create!(
                    title: card.title, content: card.content,
                    x: card.x, y: card.y, category: card.category,
                    url: card.url, image: card.image, upvotes: 0
                )
                idea_card_id_map[card.id] = new_card.id
            end

            # after_create auto-generates itinerary_days — map by day_number
            day_number_map = new_trip.itinerary_days.index_by(&:day_number)

            source.itinerary_days.includes(:itinerary_items).each do |old_day|
                new_day = day_number_map[old_day.day_number]
                next unless new_day

                old_day.itinerary_items.each do |item|
                    new_idea_card_id = idea_card_id_map[item.idea_card_id]
                    next unless new_idea_card_id

                    new_day.itinerary_items.create!(
                        idea_card_id: new_idea_card_id,
                        title: item.title, notes: item.notes,
                        order_index: item.order_index,
                        scheduled_time: item.scheduled_time,
                        time_of_day: item.time_of_day
                    )
                end
            end

            source.increment!(:duplicate_count)
        end

        render json: new_trip, status: :created
    rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Template not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    private 
    def trip_params
        params.require(:trip).permit(:name, :location, :start_date, :end_date, :image_url, :template_description, template_tags: [])
    end

    def invalid_create(error)
        render json: {message: error.message}, status: :unprocessable_entity
    end

    def render_not_found(error)
        render json: {message: error.message}, status: :not_found
    end
end
