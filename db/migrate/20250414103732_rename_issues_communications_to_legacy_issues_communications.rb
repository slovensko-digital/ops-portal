class RenameIssuesCommunicationsToLegacyIssuesCommunications < ActiveRecord::Migration[8.0]
  def change
    rename_table :issues_communications, :legacy_issues_communications
  end
end
