class AddUrlToIdeaCards < ActiveRecord::Migration[7.1]
  def change
    add_column :idea_cards, :url, :string
    add_column :idea_cards, :image, :string
  end
end
