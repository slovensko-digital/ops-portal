class AddLegacyIdToStreets < ActiveRecord::Migration[8.0]
  def change
    add_column :streets, :legacy_id, :integer
    add_index :streets, :legacy_id, unique: true
  end
end
