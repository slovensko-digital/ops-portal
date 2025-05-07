class AllowNullInIssuesCategory < ActiveRecord::Migration[8.0]
  def change
    change_column_null :issues, :category_id, true
  end
end
