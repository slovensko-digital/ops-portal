class AddDisplayNameToLegacyAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :legacy_agents, :display_name, :string

    Legacy::Agent.find_each do |agent|
      display_name = if agent.anonymous?
                       "Anonymný agent #{agent.id}"
                     else
                       [ agent.firstname, agent.lastname ].reject(&:blank?).join(" ")
                     end
      agent.update!(display_name: display_name)
    end
  end
end
