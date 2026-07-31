class AddPreferredPlacesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preferred_places, :string, array: true, default: []
  end
end
