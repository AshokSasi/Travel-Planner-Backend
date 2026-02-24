class ItineraryItem < ApplicationRecord
  belongs_to :itinerary_day, optional: true
  belongs_to :idea_card

  before_validation :nullify_invalid_itinerary_day

  private
  def nullify_invalid_itinerary_day
    if itinerary_day_id.present? && !ItineraryDay.exists?(itinerary_day_id)
      self.itinerary_day_id = nil
    end
  end
end
