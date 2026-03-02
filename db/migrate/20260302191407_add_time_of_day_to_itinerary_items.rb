class AddTimeOfDayToItineraryItems < ActiveRecord::Migration[7.1]
  def change
    add_column :itinerary_items, :time_of_day, :string
  end
end
