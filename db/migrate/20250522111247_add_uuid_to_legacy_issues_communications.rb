class AddUuidToLegacyIssuesCommunications < ActiveRecord::Migration[8.0]
  def change
    add_column :legacy_issues_communications, :uuid, :uuid
    add_index :legacy_issues_communications, :uuid, unique: true
  end
end
