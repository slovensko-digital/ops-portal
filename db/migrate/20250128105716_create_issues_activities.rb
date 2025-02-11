class CreateIssuesActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_activities do |t|
      t.references :issue, foreign_key: true, null: false
      t.string :type, null: false

      t.timestamps
    end
  end
end
