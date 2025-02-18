class AddLegacyIdToIssuesStates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_states, :legacy_id, :integer
  end
end
