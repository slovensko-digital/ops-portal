class RenameLegacyAgentsZammadIdentifierToExternalId < ActiveRecord::Migration[8.0]
  def change
    rename_column :legacy_agents, :zammad_identifier, :external_id
  end
end
