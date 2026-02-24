class CreateItineraryDays < ActiveRecord::Migration[7.1]
  def change
    create_table :itinerary_days do |t|
      t.references :trip, null: false, foreign_key: true
      t.date :date
      t.integer :day_number

      t.timestamps
    end
  end
end
