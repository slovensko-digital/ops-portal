class AddResolutionStartedAtHotPathIndexes < ActiveRecord::Migration[8.0]
  def change
    ids = Issues::State.not_visible.pluck(:id)
    add_index :issues, [ :resolution_started_at ], where: "state_id NOT IN (#{ids.join(',')}) AND resolution_started_at IS NOT NULL", name: 'index_issues_resolution_started_at_hot_path'
    add_index :issues, [ :municipality_id, :resolution_started_at ], where: "state_id NOT IN (#{ids.join(',')}) AND resolution_started_at IS NOT NULL", name: 'index_issues_municipality_resolution_started_at_hot_path'
  end
end
