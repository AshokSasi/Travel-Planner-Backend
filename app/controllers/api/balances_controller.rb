class Api::BalancesController < ApplicationController


  def balances
    trip = Trip.find(params[:id])
    balances = TripBalanceCalculator.new(trip, current_user).call
    render json: balances
  end

  private

end
