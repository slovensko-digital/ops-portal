class SyncUserUpdateToBackofficeJob < ApplicationJob
  def perform(user)
    Connector::Tenant.active.each do |tenant|
      client = Connector::BackofficeZammadEnvironment.client(tenant)
      client.update_customer(user)
    end
  end
end
