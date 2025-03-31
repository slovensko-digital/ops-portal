class AddCategoryIdToCmsPages < ActiveRecord::Migration[8.0]
  def change
    add_column :cms_pages, :category_id, :bigint, null: false
    add_foreign_key :cms_pages, :cms_categories, column: :category_id, on_delete: :cascade
  end
end
