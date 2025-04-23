class UpdateIssuesCommentsAuthor < ActiveRecord::Migration[8.0]
  def change
    remove_reference :issues_comments, :author, null: true, foreign_key: { to_table: :users }

    add_reference :issues_comments, :user_author, foreign_key: { to_table: :users }
    add_reference :issues_comments, :agent_author, foreign_key: { to_table: :legacy_agents }
    add_reference :issues_comments, :responsible_subject_author, foreign_key: { to_table: :responsible_subjects }
  end
end
