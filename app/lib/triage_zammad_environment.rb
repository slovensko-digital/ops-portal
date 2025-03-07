module TriageZammadEnvironment
  def self.client
    @client ||= ZammadApiClient.new(
      url: ENV.fetch("TRIAGE_ZAMMAD_URL"),
      http_token: ENV.fetch("TRIAGE_ZAMMAD_API_TOKEN")
    )
  end

  def self.api
    @api ||= ZammadApi.new(
      url: "#{ENV.fetch("TRIAGE_ZAMMAD_URL")}api/v1/",
      http_token: ENV.fetch("TRIAGE_ZAMMAD_API_TOKEN")
    )
  end
end
