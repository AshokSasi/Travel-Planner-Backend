class CreateTrips < ActiveRecord::Migration[7.1]
  def change
    create_table :trips do |t|
      t.string :name

      t.timestamps
    end
  end
end
