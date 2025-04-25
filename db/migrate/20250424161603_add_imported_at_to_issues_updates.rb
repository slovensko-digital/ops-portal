class AddImportedAtToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :imported_at, :datetime
  end
end
