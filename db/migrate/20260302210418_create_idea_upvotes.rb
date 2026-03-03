class CreateIdeaUpvotes < ActiveRecord::Migration[7.1]
  def change
    create_table :idea_upvotes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :idea_card, null: false, foreign_key: true

      t.timestamps
    end
    add_index :idea_upvotes, [:user_id, :idea_card_id], unique: true
  end
end
