class RemoveAgentAuthorIdFromIssuesComments < ActiveRecord::Migration[8.0]
  def change
    remove_reference :issues_comments, :agent_author, null: true, foreign_key: { to_table: :legacy_agents }
  end
end
