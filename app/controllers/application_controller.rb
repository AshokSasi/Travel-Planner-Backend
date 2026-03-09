class ApplicationController < ActionController::API
    before_action :authorize_request
    attr_reader :current_user

    private

    def authorize_request
        header = request.headers['Authorization']
        token = header.split(' ').last if header.present?
        begin
            decoded = JsonWebToken.decode(token)
           if decoded && (user = User.find_by(id: decoded[:user_id]))
                @current_user = user
           else
                render json: { errors: 'Invalid token' }, status: :unauthorized
            end
        rescue ActiveRecord::RecordNotFound => e
            render json: { errors: e.message }, status: :unauthorized
        rescue JWT::DecodeError => e
            render json: { errors: e.message }, status: :unauthorized
        end
    end
end
