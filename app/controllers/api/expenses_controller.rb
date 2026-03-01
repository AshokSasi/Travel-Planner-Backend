class Api::ExpensesController < ApplicationController
    before_action :authorize_request
    before_action :set_trip, only: [:index, :create]
    before_action :set_expense, only: [:update, :destroy]
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    include ActionView::Helpers::NumberHelper

  def index
    expenses = @trip.expenses.includes(:user)
    render json: expenses.map { |expense| expense_payload(expense) }
  end

  def create
    expense = @trip.expenses.create!(expense_params)
    render json: expense_payload(expense), status: :created
  end

  def update
    #check if the current logged in user is the one who made the expense
    unless @expense.user_id == current_user.id
      return render json: { message: "You are not authorized to update this expense" }, status: :forbidden
    end
    @expense.update!(expense_params)
    render json: expense_payload(@expense)
  end

  def destroy
    unless @expense.user_id == current_user.id
      return render json: { message: "You are not authorized to delete this expense" }, status: :forbidden
    end
    @expense.destroy
    render json: { message: "Expense deleted successfully" }
  end

  private
    def invalid_create(error)
      render json: {message: error.message}, status: :unprocessable_entity
    end

    def set_trip
      @trip = Trip.find(params[:trip_id])
    end

    def set_expense
      @expense = Expense.find(params[:id])
    end

    def render_not_found(error)
      render json: {message: error.message}, status: :not_found
    end

    def expense_params
      params.require(:expense).permit(:description, :amount, :user_id)
    end

    def lent_amount(expense)
       amount = expense.amount / expense.trip.users.count
       number_with_precision(amount, precision: 2)
    end

    def expense_payload(expense)
      expense.as_json.merge(
        "amount" => number_with_precision(expense.amount, precision: 2),
        "user_name" => expense.user&.name,
        "avatar_url" => expense.user&.avatar_url,
        "lent_amount" => lent_amount(expense)
      )
    end
end
