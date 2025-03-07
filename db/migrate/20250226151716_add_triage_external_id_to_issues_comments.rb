class AddTriageExternalIdToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :triage_external_id, :integer
  end
end
