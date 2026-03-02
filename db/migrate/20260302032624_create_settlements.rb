class CreateSettlements < ActiveRecord::Migration[7.1]
  def change
    create_table :settlements do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :receiver, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
