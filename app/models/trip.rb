
class Trip < ApplicationRecord
    has_many :idea_cards, dependent: :destroy
    has_many :itinerary_days, dependent: :destroy
    validates :name, presence: true
    validates :location, presence: true

    after_create :create_itinerary_days

    private

    def create_itinerary_days
        return unless start_date && end_date
        (start_date..end_date).each_with_index do |date, idx|
            itinerary_days.create!(date: date, day_number: idx + 1)
        end
    end
end
