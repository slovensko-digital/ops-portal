class CreateResponsibleSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects do |t|
      t.references :district, null: false, foreign_key: true
      t.references :municipality, null: false, foreign_key: true
      t.references :responsible_subject_type, null: false, foreign_key: true
      t.integer :scope
      t.string :email
      t.string :name
      t.string :code
      t.boolean :active # Predpokladam, ze status znamena toto
      t.boolean :pro

      t.timestamps
    end
  end
end
