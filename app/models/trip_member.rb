class TripMember < ApplicationRecord
  belongs_to :user
  belongs_to :trip
  validates :user_id, uniqueness: { scope: :trip_id, message: "is already a member of this trip" }
  validates :role, presence: true

  enum role:{
    owner: "owner",
    editor: "editor",
    viewer: "viewer"
  }
end
