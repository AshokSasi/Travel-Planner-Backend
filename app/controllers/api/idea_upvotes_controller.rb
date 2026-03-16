class Api::IdeaUpvotesController < ApplicationController
    before_action :set_idea, only: [ :destroy, :create ]
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_create
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # POST /api/ideas/:idea_id/upvote
  def create
    upvote = @idea.idea_upvotes.new(user: current_user)
    if upvote.save
      @idea.reload
      broadcast_upvote_update("IDEA_UPVOTE_CREATED")
      render json: { success: true, total_votes: @idea.upvoters.count, upvoted_by_current_user: true }
    else
      render json: { success: false, error: upvote.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # DELETE /api/ideas/:idea_id/upvote
  def destroy
    upvote = @idea.idea_upvotes.find_by(user: current_user)
    if upvote
      upvote.destroy
      @idea.reload
      broadcast_upvote_update("IDEA_UPVOTE_DELETED")
      render json: { success: true, total_votes: @idea.upvoters.count, upvoted_by_current_user: false }
    else
      render json: { success: false, error: "Upvote not found" }, status: :not_found
    end
  end

  private

  def set_idea
    @idea = IdeaCard.find(params[:idea_card_id])
  end

  def broadcast_upvote_update(type)
    ActionCable.server.broadcast("trip_#{@idea.trip_id}", {
      type: type,
      idea_card_id: @idea.id,
      upvotes_count: @idea.upvoters.count,
      upvoted_by: @idea.upvoters.map { |u| { id: u.id, name: u.name, email: u.email } }
    })
  end
end
