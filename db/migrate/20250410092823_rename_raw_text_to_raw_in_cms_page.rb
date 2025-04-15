class RenameRawTextToRawInCmsPage < ActiveRecord::Migration[8.0]
  def change
    rename_column :cms_pages, :raw_text, :raw
  end
end
