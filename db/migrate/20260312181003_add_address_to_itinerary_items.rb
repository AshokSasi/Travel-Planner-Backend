class AddAddressToItineraryItems < ActiveRecord::Migration[7.1]
  def change
    add_column :itinerary_items, :address, :string
  end
end
