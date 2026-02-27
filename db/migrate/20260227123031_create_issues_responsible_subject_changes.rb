class CreateIssuesResponsibleSubjectChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :issues_responsible_subject_changes do |t|
      t.references :activity, null: false, foreign_key: { to_table: :issues_activities }
      t.references :user_author, null: true, foreign_key: { to_table: :users }
      t.references :responsible_subject_author, null: true, foreign_key: { to_table: :responsible_subjects }
      t.references :responsible_subject, null: true, foreign_key: true

      t.string :text
      t.boolean :hidden, default: false, null: false
      t.integer :change_type, null: false

      t.uuid :uuid, null: false
      t.integer :triage_external_id

      t.timestamps
    end
  end
end
