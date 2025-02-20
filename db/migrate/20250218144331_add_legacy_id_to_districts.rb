class AddLegacyIdToDistricts < ActiveRecord::Migration[8.0]
  def change
    add_column :districts, :legacy_id, :integer
    add_index :districts, :legacy_id, unique: true
  end
end
