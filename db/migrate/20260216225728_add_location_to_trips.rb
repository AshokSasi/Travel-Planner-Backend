class AddLocationToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :location, :string
  end
end
