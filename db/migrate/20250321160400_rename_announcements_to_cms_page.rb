class RenameAnnouncementsToCmsPage < ActiveRecord::Migration[8.0]
  def change
    rename_table :announcements, :cms_pages
  end
end
