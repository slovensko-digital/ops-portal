class CreateResponsibleSubjectsCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects_categories do |t|
      t.references :responsible_subject, null: true, foreign_key: true
      t.references :issues_category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
