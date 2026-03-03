class AddOnboardingCompleteToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :onboarding_complete, :boolean, default: false, null: false
  end
end
