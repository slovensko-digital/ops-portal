class AddImportedAtToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :imported_at, :datetime
  end
end
