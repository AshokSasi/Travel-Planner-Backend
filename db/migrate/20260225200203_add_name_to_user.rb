class AddNameToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :text, null: false
  end
end
