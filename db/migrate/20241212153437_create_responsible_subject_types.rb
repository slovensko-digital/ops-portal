class CreateResponsibleSubjectTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subject_types do |t|
      t.string :name
      t.boolean :active # Predpokladame, ze status znamena toto

      t.timestamps
    end
  end
end
