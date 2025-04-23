class AddTypeToLegacyIssuesCommunications < ActiveRecord::Migration[8.0]
  def change
    add_column :legacy_issues_communications, :type, :string
  end
end
