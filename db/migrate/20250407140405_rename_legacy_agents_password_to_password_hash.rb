class RenameLegacyAgentsPasswordToPasswordHash < ActiveRecord::Migration[8.0]
  def change
    rename_column :legacy_agents, :password, :password_hash
  end
end
