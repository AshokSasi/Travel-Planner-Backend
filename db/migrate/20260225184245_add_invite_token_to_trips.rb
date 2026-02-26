class AddInviteTokenToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :invite_token, :string
    add_index :trips, :invite_token
  end
end
