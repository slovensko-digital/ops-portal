class AddTriageExternalIdToIssuesCommunications < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_communications, :triage_external_id, :integer
  end
end
