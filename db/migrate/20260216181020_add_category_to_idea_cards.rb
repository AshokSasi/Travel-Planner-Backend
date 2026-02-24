class AddCategoryToIdeaCards < ActiveRecord::Migration[7.1]
  def change
    add_column :idea_cards, :category, :string
    add_column :idea_cards, :upvotes, :integer, default: 0
  end
end
