class IndexSearchHotPaths2 < ActiveRecord::Migration[8.0]
  def change
    # fast index-only scan for default search homepage
    ids = Issues::State.not_visible.pluck(:id)
    add_index :issues, [ :created_at ], where: "state_id NOT IN (#{ids.join(',')})", name: 'index_issues_default_search_hot_path'
  end
end
