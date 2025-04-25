class AddImportedAtToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :imported_at, :datetime
  end
end
