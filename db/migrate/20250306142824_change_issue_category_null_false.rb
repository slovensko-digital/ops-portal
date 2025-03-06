class ChangeIssueCategoryNullFalse < ActiveRecord::Migration[8.0]
  def change
    change_column_null :issues, :category_id, false
  end
end
