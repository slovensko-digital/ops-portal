class AddStatsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stats_issues_count, :integer, default: 0
    add_column :users, :stats_comments_count, :integer, default: 0
    add_column :users, :stats_verified_issues_count, :integer, default: 0

    add_column :users, :stats_issues_percentile, :decimal, precision: 5, scale: 4, default: 0
    add_column :users, :stats_comments_percentile, :decimal, precision: 5, scale: 4, default: 0
    add_column :users, :stats_verified_issues_percentile, :decimal, precision: 5, scale: 4, default: 0
  end
end
