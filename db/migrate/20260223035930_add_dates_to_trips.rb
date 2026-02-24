class AddDatesToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :start_date, :date, null: false
    add_column :trips, :end_date, :date, null: false
  end

  add_check_constraint :trips, 
    "end_date >= start_date", 
    name: "end_date_after_start_date"
  
end
