class CreateResponsibleSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects do |t|
      t.references :district, null: true, foreign_key: true
      t.references :municipality, null: true, foreign_key: true
      t.references :responsible_subjects_type, null: false, foreign_key: true
      t.references :municipality_district, null: true, foreign_key: true
      t.integer :scope # TODO Toto nevieme co znamena, iba jeden zaznam ma nie null hodnotu
      t.string :subject_name
      t.string :email
      t.string :name
      t.string :code
      t.boolean :active # TODO Predpokladame, ze status znamena toto
      t.boolean :pro

      t.timestamps
    end
  end
end
