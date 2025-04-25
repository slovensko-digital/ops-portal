class AddImportedAtToLegacyIssuesCommunications < ActiveRecord::Migration[8.0]
  def change
    add_column :legacy_issues_communications, :imported_at, :datetime
  end
end
