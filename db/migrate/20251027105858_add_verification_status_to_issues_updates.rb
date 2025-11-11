class AddVerificationStatusToIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_updates, :verification_status, :integer, default: 0, null: false
  end
end
