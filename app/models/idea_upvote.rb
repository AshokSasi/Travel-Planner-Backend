class IdeaUpvote < ApplicationRecord
  belongs_to :user
  belongs_to :idea_card
  validates :user_id, uniqueness: { scope: :idea_card_id } 
end
