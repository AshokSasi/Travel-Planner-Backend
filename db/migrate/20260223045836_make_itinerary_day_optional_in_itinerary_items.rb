class MakeItineraryDayOptionalInItineraryItems < ActiveRecord::Migration[7.1]
  def change
    change_column_null :itinerary_items, :itinerary_day_id, true
  end
end
