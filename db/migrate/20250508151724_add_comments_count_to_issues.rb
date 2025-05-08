class AddCommentsCountToIssues < ActiveRecord::Migration[8.0]
  def up
    add_column :issues, :comments_count, :integer, default: 0, null: false

    Issue.reset_column_information

    Issue.find_each { |issue| issue.reset_counters }
  end

  def down
    remove_column :issues, :comments_count
  end
end
