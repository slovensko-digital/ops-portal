class CreateConnectorIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :connector_issues do |t|
      t.integer :triage_external_id, index: { unique: true }
      t.integer :backoffice_external_id, index: { unique: true }

      t.timestamps
    end
  end
end
