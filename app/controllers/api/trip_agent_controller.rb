class Api::TripAgentController < ApplicationController
    MAX_MESSAGE_LENGTH = 2000
    HISTORY_PAGE = 100

    before_action :set_trip
    before_action :require_member
    before_action :require_editor, only: [ :create, :apply, :discard ]
    before_action :set_proposal, only: [ :apply, :discard ]
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    def index
        messages = @trip.trip_agent_messages.includes(:user, proposal: :resolved_by)
                        .order(created_at: :desc).limit(HISTORY_PAGE).to_a.reverse
        render json: { messages: messages.map(&:as_json) }
    end

    def create
        content = params[:content].to_s.strip
        if content.empty? || content.length > MAX_MESSAGE_LENGTH
            return render json: { error: "Message must be 1-#{MAX_MESSAGE_LENGTH} characters" }, status: :unprocessable_entity
        end

        message, reply = TripAgentService.new(@trip, current_user, content).call
        [ message, reply ].each do |m|
            ActionCable.server.broadcast("trip_#{@trip.id}", { type: "AGENT_MESSAGE_CREATED", item: m.as_json })
        end
        render json: { message: message.as_json, reply: reply.as_json }, status: :created
    rescue ::Anthropic::Errors::Error => e
        status = e.respond_to?(:status) ? e.status : nil
        Rails.logger.error("[TripAgent] trip=#{@trip.id} #{e.class} status=#{status} #{e.message.to_s[0, 500]}")
        render json: { error: "The trip assistant is temporarily unavailable, please try again later" }, status: :service_unavailable
    rescue TripAgentService::AgentError => e
        render json: { error: e.message }, status: :unprocessable_entity
    end

    def apply
        applier = TripAgentProposalApplier.new(@proposal, current_user, params[:change_ids])
        proposal = applier.call
        render json: { proposal: proposal.as_json, item_ids: applier.touched_item_ids }
    rescue TripAgentProposalApplier::StaleError => e
        render json: { error: e.message, proposal: @proposal.reload.as_json }, status: :conflict
    rescue TripAgentProposalApplier::InvalidError => e
        render json: { error: e.message, proposal: @proposal.reload.as_json }, status: :unprocessable_entity
    end

    def discard
        unless @proposal.pending?
            return render json: { error: "This proposal was already #{@proposal.status}", proposal: @proposal.as_json },
                          status: :unprocessable_entity
        end

        @proposal.resolve!("discarded", current_user)
        ActionCable.server.broadcast("trip_#{@trip.id}", { type: "AGENT_PROPOSAL_UPDATED", item: @proposal.as_json })
        render json: { proposal: @proposal.as_json }
    end

    private

    def set_trip
        @trip = Trip.find(params[:trip_id])
    end

    def require_member
        @membership = @trip.trip_members.find_by(user: current_user)
        render json: { error: "You're not a member of this trip" }, status: :forbidden unless @membership
    end

    def require_editor
        return unless @membership&.viewer?
        render json: { error: "Viewers can read the assistant chat but can't make changes" }, status: :forbidden
    end

    def set_proposal
        @proposal = @trip.trip_agent_proposals.find(params[:proposal_id])
    end

    def render_not_found(error)
        render json: { message: error.message }, status: :not_found
    end
end
