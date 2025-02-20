class AddLegacyIdToMunicipalityDistricts < ActiveRecord::Migration[8.0]
  def change
    add_column :municipality_districts, :legacy_id, :integer
    add_index :municipality_districts, :legacy_id, unique: true
  end
end
