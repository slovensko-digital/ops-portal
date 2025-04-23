class UpdateIssuesCommunicationsAuthor < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_communications, :author_id, :bigint
    remove_column :issues_communications, :author_type, :string

    add_reference :issues_communications, :agent_author, foreign_key: { to_table: :legacy_agents }
    add_reference :issues_communications, :responsible_subjects_user_author, foreign_key: { to_table: :responsible_subjects_users }
  end
end
