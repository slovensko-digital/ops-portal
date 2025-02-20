class AddLegacyIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :legacy_id, :integer
    add_index :users, :legacy_id, unique: true
  end
end
