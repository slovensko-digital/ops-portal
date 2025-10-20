class AddActiveToMunicipalityDistricts < ActiveRecord::Migration[8.0]
  def up
    add_column :municipality_districts, :active, :boolean, default: false

    execute <<-SQL.squish
      UPDATE municipality_districts
      SET active = municipalities.active
      FROM municipalities
      WHERE municipality_districts.municipality_id = municipalities.id
    SQL
  end

  def down
    remove_column :municipality_districts, :active
  end
end
