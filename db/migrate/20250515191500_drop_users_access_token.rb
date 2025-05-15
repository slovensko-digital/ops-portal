class DropUsersAccessToken < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :access_token, :string
  end
end
