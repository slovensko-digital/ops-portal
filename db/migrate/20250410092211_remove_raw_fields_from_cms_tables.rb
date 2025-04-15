class RemoveRawFieldsFromCmsTables < ActiveRecord::Migration[8.0]
  def up
    remove_column :cms_categories, :raw
    remove_column :cms_pages, :raw
  end

  def down
    add_column :cms_categories, :raw, :jsonb, null: false, default: {}
    add_column :cms_pages, :raw, :jsonb, null: false, default: {}
  end
end
