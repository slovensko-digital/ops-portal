class AddDisplayNameToLegacyAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :legacy_agents, :display_name, :string
  end
end
