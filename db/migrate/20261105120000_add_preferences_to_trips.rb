class AddPreferencesToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :preferences, :jsonb, default: {}, null: false
  end
end
