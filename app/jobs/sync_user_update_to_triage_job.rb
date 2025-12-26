class SyncUserUpdateToTriageJob < ApplicationJob
  def perform(user, client: TriageZammadEnvironment.client)
    client.update_customer(user)
  end
end
