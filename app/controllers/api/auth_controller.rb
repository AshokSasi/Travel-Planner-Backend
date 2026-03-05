require 'net/http'

class Api::AuthController < ApplicationController
    skip_before_action :authorize_request, only: [:signup, :login, :google]
    def signup
        user = User.new(user_params)
        if user.save
            token = JsonWebToken.encode(user_id: user.id)
            render json: { token: token, user:user.as_json(only: [:id, :name, :email]), message: 'User created successfully' }, status: :created
        else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def login 
        user = User.find_by(email: params[:email].downcase)
        if user&.authenticate(params[:password])
            token = JsonWebToken.encode(user_id: user.id)
            render json: { token: token, user: user, message: 'Login successful' }, status: :ok
        else
            render json: { errors: 'Invalid email or password' }, status: :unauthorized
        end
    end

    def google
        google_token = params[:google_token]

        google_user = fetch_google_user_info(google_token)
        return unless google_user

        email = google_user['email']&.downcase
        unless email.present?
            return render json: { errors: 'Invalid Google token' }, status: :unauthorized
        end

        user = User.find_or_initialize_by(email: email)
        if user.new_record?
            user.name = google_user['name']
            user.password = "Itinify_" + SecureRandom.hex(12)
            user.google_avatar_url = google_user['picture']
            unless user.save
                return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
            end
        end

        token = JsonWebToken.encode(user_id: user.id)
        render json: {
            token: token,
            user: user.as_json(only: [:id, :name, :email, :onboarding_complete, :tutorial_complete], methods: :avatar_url)
        }, status: :ok
    end

    private

    def fetch_google_user_info(google_token)
        uri = URI('https://www.googleapis.com/oauth2/v3/userinfo')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{google_token}"

        response = http.request(request)

        if response.code.to_i == 401
            render json: { errors: 'Invalid Google token' }, status: :unauthorized
            return nil
        elsif !response.is_a?(Net::HTTPSuccess)
            render json: { errors: 'Failed to fetch Google user info' }, status: :bad_gateway
            return nil
        end

        JSON.parse(response.body)
    rescue StandardError
        render json: { errors: 'Failed to connect to Google' }, status: :bad_gateway
        nil
    end

    def user_params
        params.require(:auth).permit(:email, :password, :password_confirmation, :name)
    end
end
