class AddAddressToIdeaCards < ActiveRecord::Migration[7.1]
  def change
    add_column :idea_cards, :address, :string
  end
end
