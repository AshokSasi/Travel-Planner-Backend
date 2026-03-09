class AddTemplateToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :is_template, :boolean, default: false
    add_column :trips, :template_description, :string
    add_column :trips, :template_tags, :string, array: true, default: []
    add_column :trips, :duplicate_count, :integer, default: 0
    add_column :trips, :published_at, :datetime
  end
end
