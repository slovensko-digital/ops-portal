class RemoveOrganizationFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :organization, :boolean
  end
end
