class CreateResponsibleSubjectsOrganizationUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects_organization_units do |t|
      t.references :responsible_subject, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
