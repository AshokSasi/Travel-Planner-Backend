class Api::ItineraryGeneratorController < ApplicationController
  def questions
    trip = Trip.find(params[:id])

    questions = ItineraryQuestionsService.new(trip, preferences).call
    render json: { questions: questions }, status: :ok
  rescue ::Anthropic::Errors::Error => e
    render json: { error: "AI questions are temporarily unavailable, please try again later" }, status: :service_unavailable
  rescue => e
    render json: { error: "Failed to generate questions: #{e.message}" }, status: :internal_server_error
  end

  def generate
    trip = Trip.find(params[:id])

    days = ItineraryGeneratorService.new(trip, preferences).call
    # Kept so the trip assistant knows the group's budget and style later
    trip.update!(preferences: preferences.to_h)
    render json: { success: true, itinerary: days }, status: :ok
  rescue ::Anthropic::Errors::Error => e
    render json: { error: "AI generation is temporarily unavailable, please try again later" }, status: :service_unavailable
  rescue ItineraryGeneratorService::TruncatedResponseError => e
    render json: { error: "#{e.message}. Try fewer regions or a shorter trip." }, status: :unprocessable_entity
  rescue JSON::ParserError => e
    render json: { error: "Failed to parse itinerary response: #{e.message}" }, status: :unprocessable_entity
  rescue => e
    render json: { error: "Failed to generate itinerary: #{e.message}" }, status: :internal_server_error
  end

  private

  # Saved on the trip after a successful generation for the trip assistant to use
  def preferences
    params.permit(:budget, :travel_style, :group_type, :pace, :notes,
                  interests: [], regions: [], answers: [ :question, :answer, { answer: [] } ])
  end
end
