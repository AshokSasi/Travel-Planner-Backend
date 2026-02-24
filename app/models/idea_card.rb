class IdeaCard < ApplicationRecord
  belongs_to :trip
  has_many :itinerary_items, dependent: :destroy
end
