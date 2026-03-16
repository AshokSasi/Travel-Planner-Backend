class User < ApplicationRecord
    has_secure_password
    validates :email, presence: true, uniqueness: true
    before_save :downcase_email
    has_many :trip_members, dependent: :destroy
    has_many :trips, through: :trip_members
    has_one_attached :avatar
    validate :avatar_size
    has_many :paid_settlements, class_name: "Settlement", foreign_key: "user_id"
    has_many :received_settlements, class_name: "Settlement", foreign_key: "receiver_id"
    has_many :idea_upvotes, dependent: :destroy
    has_many :upvoted_idea_cards, through: :idea_upvotes, source: :idea_card
    validates :password, presence: true, length: { minimum: 8 }, on: :create
    validates :password,
      length: { minimum: 8 },
      format: {
        with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
        message: "must include at least one uppercase letter, one lowercase letter, and one number"
      },
      allow_nil: true

    def avatar_url
        if avatar.attached?
            Rails.application.routes.url_helpers.url_for(avatar)
        else
            google_avatar_url
        end
    end


    private
    def avatar_size
        if avatar.attached? && avatar.blob.byte_size > 5.megabytes
            errors.add(:avatar, "is too big")
        end
    end

    def downcase_email
        self.email = email.downcase
    end
end
