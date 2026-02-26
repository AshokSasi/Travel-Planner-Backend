class CreateTripMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.string :role

      t.timestamps
    end

  end
end
