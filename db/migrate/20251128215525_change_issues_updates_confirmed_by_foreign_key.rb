class ChangeIssuesUpdatesConfirmedByForeignKey < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues_updates, :confirmed_by_id, :integer
    add_reference :issues_updates, :confirmed_by, foreign_key: { to_table: :legacy_agents }
  end
end
