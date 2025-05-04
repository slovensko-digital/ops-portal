class AddVoteCountersToIssuesActivity < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_activities, :likes_count, :integer, null: false, default: 0
    add_column :issues_activities, :dislikes_count, :integer, null: false, default: 0
  end
end
