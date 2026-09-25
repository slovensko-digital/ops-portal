class CreateIssuesStateChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :issues_state_changes do |t|
      t.references :activity, null: false, foreign_key: { to_table: :issues_activities }
      t.references :previous_state, null: true, foreign_key: { to_table: :issues_states }
      t.references :new_state, null: false, foreign_key: { to_table: :issues_states }

      t.boolean :hidden, default: false, null: false
      t.uuid :uuid, null: false
      t.integer :triage_external_id

      t.timestamps
    end
  end
end
