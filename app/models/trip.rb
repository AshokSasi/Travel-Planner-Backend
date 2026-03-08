
class Trip < ApplicationRecord
    has_many :idea_cards, dependent: :destroy
    has_many :itinerary_days, dependent: :destroy
    validates :name, presence: true
    validates :location, presence: true
    has_many :trip_members, dependent: :destroy
    has_many :expenses, dependent: :destroy
    has_many :users, through: :trip_members
    after_create :create_itinerary_days
    after_update :sync_itinerary_days, if: -> { saved_change_to_start_date? || saved_change_to_end_date? }
    before_create :generate_invite_token
    has_many :settlements, dependent: :destroy
    has_many :categories, dependent: :destroy
    private

    def create_itinerary_days
        return unless start_date && end_date
        (start_date..end_date).each_with_index do |date, idx|
            itinerary_days.create!(date: date, day_number: idx + 1)
        end
    end

    def sync_itinerary_days
        return unless start_date && end_date

        new_dates = (start_date..end_date).to_a

        # Nullify items on removed days, then delete those days
        itinerary_days.where.not(date: new_dates).destroy_all

        # Create days for any new dates
        existing_dates = itinerary_days.pluck(:date)
        new_dates.each_with_index do |date, idx|
            itinerary_days.create!(date: date, day_number: idx + 1) unless existing_dates.include?(date)
        end

        # Renumber all days in order
        itinerary_days.order(:date).each_with_index do |day, idx|
            day.update_columns(day_number: idx + 1)
        end
    end
    
    def generate_invite_token
        self.invite_token = SecureRandom.urlsafe_base64(16)
    end
end
