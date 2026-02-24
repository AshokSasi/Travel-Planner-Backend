class CreateIdeaCards < ActiveRecord::Migration[7.1]
  def change
    create_table :idea_cards do |t|
      t.string :title
      t.text :content
      t.float :x
      t.float :y
      t.references :trip, null: false, foreign_key: true

      t.timestamps
    end
  end
end
