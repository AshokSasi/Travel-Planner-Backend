class AddGoogleAvatarUrlToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :google_avatar_url, :string
  end
end
