class AddOwnerToIssues < ActiveRecord::Migration[8.0]
  def change
    add_reference :issues, :owner, null: true, foreign_key: { to_table: :users }
  end
end
