class CreateResponsibleSubjectsTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects_types do |t|
      t.string :name
      t.boolean :active # TODO Predpokladame, ze status znamena toto

      t.timestamps
    end
  end
end
