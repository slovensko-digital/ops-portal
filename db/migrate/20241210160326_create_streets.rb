class CreateStreets < ActiveRecord::Migration[8.0]
  def change
    create_table :streets do |t|
      t.string :name
      t.references :municipality, null: false, foreign_key: true
      t.references :municipality_district, null: false, foreign_key: true
      t.string :place_id
      t.float :latitude
      t.float :longitude
      t.boolean :tested

      t.timestamps

      t.index :latitude
      t.index :longitude
    end
  end
end
