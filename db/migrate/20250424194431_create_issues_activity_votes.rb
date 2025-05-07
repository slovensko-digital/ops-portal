class CreateIssuesActivityVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_activity_votes do |t|
      t.belongs_to :activity, null: false
      t.belongs_to :voter, null: false
      t.integer :vote, null: false, limit: 1

      t.timestamps
    end

    add_foreign_key :issues_activity_votes, :issues_activities, column: :activity_id, on_delete: :cascade
    add_foreign_key :issues_activity_votes, :users, column: :voter_id, on_delete: :cascade
    add_index :issues_activity_votes, [ :activity_id, :voter_id ], unique: true
  end
end
