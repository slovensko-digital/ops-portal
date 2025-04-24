class IndexGeoSearch < ActiveRecord::Migration[8.0]
  def change
    add_index :issues, "(ST_Point(longitude, latitude, 4326)::geography)", using: :gist, name: "index_issues_on_location"
  end
end
