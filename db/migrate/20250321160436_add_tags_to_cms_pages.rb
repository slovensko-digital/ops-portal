class AddTagsToCmsPages < ActiveRecord::Migration[8.0]
  def change
    add_column :cms_pages, :tags, :string, array: true, default: []
  end
end
