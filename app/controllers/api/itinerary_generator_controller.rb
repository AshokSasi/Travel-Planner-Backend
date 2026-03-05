class Api::ItineraryGeneratorController < ApplicationController
  def generate
    trip = Trip.find(params[:id])

    preferences = params.permit(:budget, :travel_style, :group_type)
    days = ItineraryGeneratorService.new(trip, preferences).call
    render json: { success: true, itinerary: days }, status: :ok
  rescue ::Anthropic::Errors::Error => e
    render json: { error: "AI generation is temporarily unavailable, please try again later" }, status: :service_unavailable
  rescue JSON::ParserError => e
    render json: { error: "Failed to parse itinerary response: #{e.message}" }, status: :unprocessable_entity
  rescue => e
    render json: { error: "Failed to generate itinerary: #{e.message}" }, status: :internal_server_error
  end
end
