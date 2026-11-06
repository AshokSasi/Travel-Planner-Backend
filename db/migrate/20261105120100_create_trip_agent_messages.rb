class CreateTripAgentMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_agent_messages do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false, default: ""
      t.timestamps
    end
    add_index :trip_agent_messages, [ :trip_id, :created_at ]
  end
end
