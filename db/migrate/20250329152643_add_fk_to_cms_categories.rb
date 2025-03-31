class AddFkToCmsCategories < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :cms_categories, :cms_categories, column: :parent_category_id
  end
end
