class AddCommentLegacyIdToIssuesComments < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_comments, :legacy_comment_id, :integer
    add_index :issues_comments, :legacy_comment_id, unique: true
  end
end
