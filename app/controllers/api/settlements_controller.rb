class Api::SettlementsController < ApplicationController
    before_action :authorize_request
    before_action :set_trip, only: [ :index, :create ]
    before_action :set_settlement, only: [ :show ]
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    include ActionView::Helpers::NumberHelper

  def index
    settlements = @trip.settlements.includes(:user, :receiver).order(created_at: :desc)
      render json: settlements.map { |settlement| settlement_payload(settlement) }
  end

  def show
    render json: settlement_payload(@settlement)
  end

  def create
    trip = Trip.find(params[:trip_id])

    settlement = trip.settlements.new(settlement_params)
    settlement.user_id = current_user.id

    if settlement.save
        render json: settlement_payload(settlement), status: :created
    else
      render json: { errors: settlement.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
    def invalid_create(error)
      render json: { message: error.message }, status: :unprocessable_entity
    end

    def set_trip
      @trip = Trip.find(params[:trip_id])
    end

    def set_settlement
      @settlement = Settlement.find(params[:id])
    end

    def render_not_found(error)
      render json: { message: error.message }, status: :not_found
    end

    def settlement_params
      params.require(:settlement).permit(:receiver_id, :amount, :user_id)
    end

      def settlement_payload(settlement)
        settlement.as_json.merge(
          "user_name" => settlement.user&.name,
          "receiver_name" => settlement.receiver&.name
        )
      end
  # def lent_amount(expense)
  #    amount = expense.amount / expense.trip.users.count
  #    number_with_precision(amount, precision: 2)
  # end

  # def expense_payload(expense)
  #   expense.as_json.merge(
  #     "amount" => number_with_precision(expense.amount, precision: 2),
  #     "user_name" => expense.user&.name,
  #     "avatar_url" => expense.user&.avatar_url,
  #     "lent_amount" => lent_amount(expense)
  #   )
  # end
end
