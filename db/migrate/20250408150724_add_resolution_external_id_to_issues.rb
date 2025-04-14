class AddResolutionExternalIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :resolution_external_id, :integer
  end
end
