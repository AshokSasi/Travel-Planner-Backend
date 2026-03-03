class ChangeTutorialCompleteDefault < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :tutorial_complete, from: nil, to: false
    change_column_null :users, :tutorial_complete, false, false
  end
end
