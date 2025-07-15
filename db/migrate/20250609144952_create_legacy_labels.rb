class CreateLegacyLabels < ActiveRecord::Migration[8.0]
  def change
    create_table :legacy_labels do |t|
      t.integer :legacy_id
      t.references :responsible_subject, null: false, foreign_key: true
      t.string :name
      t.string :color

      t.timestamps

      t.index :legacy_id, unique: true
    end
  end
end
