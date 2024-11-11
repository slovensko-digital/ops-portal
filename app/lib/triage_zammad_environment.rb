module TriageZammadEnvironment
  def self.client
    @client ||= ZammadAPI::Client.new(
      url: ENV.fetch("TRIAGE_ZAMMAD_URL"),
      http_token: ENV.fetch("TRIAGE_ZAMMAD_API_TOKEN")
    )
  end
end
