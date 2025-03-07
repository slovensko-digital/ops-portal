class DropLegacyRightsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :legacy_rights, :integer
  end
end
