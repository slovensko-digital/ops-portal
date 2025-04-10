class AddLatlonFromExifToIssuesDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :latlon_from_exif, :boolean, default: false
  end
end
