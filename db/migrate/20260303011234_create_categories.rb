class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :name
      t.string :color, null: false
      t.float   :x,     default: 0
      t.float   :y,     default: 0
      t.float   :width, default: 350
      t.float   :height, default: 350

      t.timestamps
    end
  end
end
