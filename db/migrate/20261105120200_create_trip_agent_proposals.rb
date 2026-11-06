class CreateTripAgentProposals < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_agent_proposals do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :trip_agent_message, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.jsonb :changes_list, null: false, default: []
      t.jsonb :applied_change_ids, null: false, default: []
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.timestamps
    end
  end
end
