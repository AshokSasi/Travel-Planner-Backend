class IdeaCard < ApplicationRecord
  belongs_to :trip
  has_many :itinerary_items, dependent: :destroy
  has_many :idea_upvotes, dependent: :destroy
  has_many :upvoters, through: :idea_upvotes, source: :user
end
