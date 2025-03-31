class AddIndexesToCmsModels < ActiveRecord::Migration[8.0]
  def change
    add_index :cms_categories, [ :parent_category_id, :slug ], unique: true
    add_index :cms_pages, [ :category_id, :slug ], unique: true
  end
end
