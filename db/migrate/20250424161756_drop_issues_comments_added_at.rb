class DropIssuesCommentsAddedAt < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_comments, :added_at, :datetime
  end
end
