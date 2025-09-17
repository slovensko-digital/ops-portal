class AddSpatialIndexToIssues < ActiveRecord::Migration[7.1]
  def change
    add_index :issues, "ST_Point(longitude, latitude, 4326)", using: :gist, name: "index_issues_on_lat_lon_point"
  end
end
