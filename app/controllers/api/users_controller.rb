class Api::UsersController < ApplicationController
    before_action :authorize_request
    before_action :set_user, only: [:update]
    def me
        render json: current_user.as_json(only: [:id, :name, :email]), status: :ok
    end

    def update
        if params[:new_password].present? && params[:password_confirmation].present?
            unless current_user.authenticate(params[:current_password])
                return render json: { errors: 'Current password is incorrect' }, status: :unauthorized
            end

            unless params[:new_password] == params[:password_confirmation]
                return render json: { errors: 'New password and confirmation do not match' }, status: :unprocessable_entity
            end

            @user.update!(password: params[:new_password])
            return  render json: @user.as_json(only: [:id, :name, :email]), status: :ok
        end

        @user.update!(user_params)
        render json: @user.as_json(only: [:id, :name, :email]), status: :ok
    rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
    end

    private

    def user_params
        params.permit(:name, :email, :password, :password_confirmation, :current_password, :new_password)
    end

    def set_user
        @user = User.find(params[:id])
    end
end
