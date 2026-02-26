class Api::UserController < ApplicationController

    def me
        render json: current_user.as_json(only: [:id, :name, :email]), status: :ok
    end
end
