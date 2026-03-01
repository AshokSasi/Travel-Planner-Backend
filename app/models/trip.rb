
class Trip < ApplicationRecord
    has_many :idea_cards, dependent: :destroy
    has_many :itinerary_days, dependent: :destroy
    validates :name, presence: true
    validates :location, presence: true
    has_many :trip_members, dependent: :destroy
    has_many :expenses, dependent: :destroy
    has_many :users, through: :trip_members
    after_create :create_itinerary_days
    before_create :generate_invite_token
    
    private

    def create_itinerary_days
        return unless start_date && end_date
        (start_date..end_date).each_with_index do |date, idx|
            itinerary_days.create!(date: date, day_number: idx + 1)
        end
    end
    
    def generate_invite_token
        self.invite_token = SecureRandom.urlsafe_base64(16)
        self.invite_expires_at = 7.days.from_now
    end
end
