module TriageZammadEnvironment
  OPS_PORTAL_ARTICLE_TAG = "[[ops portal]]"
  RESPONSIBLE_SUBJECT_ARTICLE_TAG = "[[pre zodpovedny subjekt]]"
  MARKED_AS_RESOLVED_TAG = "[[vyriesene]]"

  def self.client
    @client ||= ZammadApiClient.new(
      url: ENV.fetch("TRIAGE_ZAMMAD_URL"),
      http_token: ENV.fetch("TRIAGE_ZAMMAD_API_TOKEN")
    )
  end
end
