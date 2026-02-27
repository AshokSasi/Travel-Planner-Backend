class User < ApplicationRecord
    has_secure_password
    validates :email, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }, on: :create
    before_save :downcase_email
    has_many :trip_member, dependent: :destroy
    has_many :trips, through: :trip_member
    private
    def downcase_email
        self.email = email.downcase
    end 
end
