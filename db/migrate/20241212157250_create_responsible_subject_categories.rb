class CreateResponsibleSubjectCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subject_categories do |t|
      t.references :responsible_subject, null: false, foreign_key: true
      t.references :issue_category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
