class CreateIssueSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_subscriptions do |t|
      t.belongs_to :issue, null: false
      t.belongs_to :subscriber, null: false

      t.timestamps
    end

    add_foreign_key :issue_subscriptions, :issues, on_delete: :cascade
    add_foreign_key :issue_subscriptions, :users, column: :subscriber_id, on_delete: :cascade
    add_index :issue_subscriptions, [ :issue_id, :subscriber_id ], unique: true
  end
end
