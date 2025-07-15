class AddExternalIdToIssuesUpdate < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :external_id, :string
    add_index :issues_updates, :external_id, unique: true
  end
end
