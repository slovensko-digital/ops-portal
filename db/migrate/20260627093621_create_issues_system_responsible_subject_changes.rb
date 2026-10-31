class CreateIssuesSystemResponsibleSubjectChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :issues_system_responsible_subject_changes do |t|
      t.references :activity, null: false, foreign_key: { to_table: :issues_activities }
      t.references :previous_responsible_subject, foreign_key: { to_table: :responsible_subjects }
      t.references :new_responsible_subject, foreign_key: { to_table: :responsible_subjects }

      t.boolean :hidden, default: false, null: false
      t.uuid :uuid, null: false

      t.timestamps
    end
  end
end
