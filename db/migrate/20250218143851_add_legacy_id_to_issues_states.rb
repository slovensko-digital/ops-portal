class AddLegacyIdToIssuesStates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_states, :legacy_id, :integer
    add_index :issues_states, :legacy_id, unique: true
  end
end
