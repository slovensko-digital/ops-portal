class AddLegacyIdToMunicipalities < ActiveRecord::Migration[8.0]
  def change
    add_column :municipalities, :legacy_id, :integer
    add_index :municipalities, :legacy_id, unique: true
  end
end
