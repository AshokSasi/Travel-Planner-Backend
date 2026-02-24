class AddScheduledTimeToItineraryItems < ActiveRecord::Migration[7.1]
  def change
    add_column :itinerary_items, :scheduled_time, :time, null: true
  end
end
