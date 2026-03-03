class AddTutorialCompleteToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :tutorial_complete, :boolean
  end
end
