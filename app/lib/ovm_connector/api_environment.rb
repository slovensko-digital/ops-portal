module OvmConnector::ApiEnvironment
  def self.zammad_client
    @zammad_client ||= ZammadAPI::Client.new(
      url: ENV.fetch("CONNECTOR__OVM_ZAMMAD_URL"),
      http_token: ENV.fetch("CONNECTOR__OVM_ZAMMAD_API_TOKEN")
    )
  end
end
