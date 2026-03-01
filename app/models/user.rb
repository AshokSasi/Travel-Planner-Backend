class User < ApplicationRecord
    has_secure_password
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }, on: :create
    before_save :downcase_email
    has_many :trip_member, dependent: :destroy
    has_many :trips, through: :trip_member
    has_one_attached :avatar
    validate :avatar_size

    def avatar_url
        Rails.application.routes.url_helpers.url_for(avatar) if avatar.attached?
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
