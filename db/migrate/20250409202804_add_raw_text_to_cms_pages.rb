class AddRawTextToCmsPages < ActiveRecord::Migration[8.0]
  def up
    add_column :cms_pages, :raw_text, :text

    Cms::Page.reset_column_information

    Cms::Page.update_all(raw_text: "")

    change_column_null :cms_pages, :raw_text, false
  end

  def down
    remove_column :cms_pages, :raw_text
  end
end
