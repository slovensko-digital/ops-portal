class CreateMunicipalities < ActiveRecord::Migration[8.0]
  def change
    create_table :municipalities do |t|
      t.string :name
      t.references :district, null: false, foreign_key: true
      t.string :sub
      t.string :alias
      t.string :email
      t.integer :municipality_type
      t.boolean :has_municipality_districts
      t.integer :handled_by
      t.float :latitude
      t.float :longitude
      t.integer :population
      t.boolean :active
      t.integer :category
      t.string :languages
      t.string :logo

      t.timestamps

      t.index :alias
      t.index :latitude
      t.index :longitude
      t.index :active
    end
  end
end
