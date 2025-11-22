class IndexSearchHotPaths3 < ActiveRecord::Migration[8.0]
  def change
    # fast index-only scan for default search homepage
    ids = Issues::State.not_visible.pluck(:id)

    remove_index :issues, :created_at, name: 'index_issues_default_search_hot_path'

    add_index :issues, [ :effective_at ], where: "state_id NOT IN (#{ids.join(',')})", name: 'index_issues_default_search_hot_path'
    add_index :issues, [ :municipality_id, :effective_at ], where: "state_id NOT IN (#{ids.join(',')})", name: 'index_issues_municipality_effective_at_hot_path'
  end
end
