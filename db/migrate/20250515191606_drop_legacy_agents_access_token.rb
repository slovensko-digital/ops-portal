class DropLegacyAgentsAccessToken < ActiveRecord::Migration[8.0]
  def change
    remove_column :legacy_agents, :access_token, :string
  end
end
