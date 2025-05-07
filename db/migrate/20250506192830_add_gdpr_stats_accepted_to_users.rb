class AddGdprStatsAcceptedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :gdpr_stats_accepted, :boolean, default: false
  end
end
