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
        token = params[:google_token]
        validator = GoogleIDToken::Validator.new
        begin
            payload = validator.check(token, ENV['GOOGLE_CLIENT_ID'])
            user = User.find_or_create_by(email: payload['email']) do |u|
                u.name = payload['name']
                u.password = SecureRandom.hex(16) # Generate a random password for Google users
            end
            jwt_token = JsonWebToken.encode(user_id: user.id)
            render json: { token: jwt_token, user: user, message: 'Google login successful' }, status: :ok
        rescue GoogleIDToken::ValidationError => e
            render json: { errors: "Invalid Google token: #{e.message}" }, status: :unauthorized
        end
    end

    private
    def user_params
        params.require(:auth).permit(:email, :password, :password_confirmation, :name)
    end
end
