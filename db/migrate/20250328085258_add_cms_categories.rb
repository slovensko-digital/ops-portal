class AddCmsCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :cms_categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.bigint :parent_category_id
      t.jsonb :raw, null: false, default: {}

      t.timestamps
    end
  end
end
