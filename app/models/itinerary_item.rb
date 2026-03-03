class ItineraryItem < ApplicationRecord
  belongs_to :itinerary_day, optional: true
  belongs_to :idea_card
  TIMES_OF_DAY = %w[morning afternoon evening].freeze
  before_validation :nullify_invalid_itinerary_day
  validates :time_of_day, inclusion: { in: TIMES_OF_DAY }, allow_nil: true
  before_validation :assign_time_of_day_from_time, unless: -> { time_of_day.present? }
  private
  def nullify_invalid_itinerary_day
    if itinerary_day_id.present? && !ItineraryDay.exists?(itinerary_day_id)
      self.itinerary_day_id = nil
    end
  end

   def assign_time_of_day_from_time
    return unless scheduled_time.present?

    hour = scheduled_time.hour
    self.time_of_day =
      if hour < 12
        "morning"
      elsif hour < 18
        "afternoon"
      else
        "evening"
      end
  end
end
