class AddCityToItineraryDays < ActiveRecord::Migration[7.1]
  def change
    add_column :itinerary_days, :city, :string
  end
end
