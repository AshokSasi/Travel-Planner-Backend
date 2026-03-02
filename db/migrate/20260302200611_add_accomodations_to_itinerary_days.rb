class AddAccomodationsToItineraryDays < ActiveRecord::Migration[7.1]
  def change
    add_column :itinerary_days, :accomodation_name, :string
    add_column :itinerary_days, :accomodation_address, :string
  end
end
