class AddDiscussionClosedToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :discussion_closed, :boolean, default: false
  end
end
