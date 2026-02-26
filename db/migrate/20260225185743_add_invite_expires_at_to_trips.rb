class AddInviteExpiresAtToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :invite_expires_at, :datetime
  end
end
