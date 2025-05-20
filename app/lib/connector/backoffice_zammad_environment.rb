module Connector::BackofficeZammadEnvironment
  def self.client(tenant)
    @clients ||= {}
    @clients[tenant.id] ||= Connector::ZammadApiClient.new(tenant)
  end
end
