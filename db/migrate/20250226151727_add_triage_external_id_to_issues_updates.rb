class AddTriageExternalIdToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :triage_external_id, :integer
  end
end
