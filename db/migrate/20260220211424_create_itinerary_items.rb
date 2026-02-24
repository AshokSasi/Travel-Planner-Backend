class CreateItineraryItems < ActiveRecord::Migration[7.1]
  def change
    create_table :itinerary_items do |t|
      t.references :itinerary_day, null: false, foreign_key: true
      t.references :idea_card, null: false, foreign_key: true
      t.string :title
      t.text :notes
      t.integer :order_index

      t.timestamps
    end
  end
end
