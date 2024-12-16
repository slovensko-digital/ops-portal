class Connector::OpsApiClient
  def initialize(tenant, url: ENV.fetch("CONNECTOR__OPS_API_URL"), provider: Faraday)
    @subject = tenant.api_subject_identifier
    @private_key = OpenSSL::PKey::EC.new(tenant.api_token_private_key)
    @url = url
    @provider = provider
  end

  def get_issue(issue_id)
    response = @provider.get(URI.join(@url, "api/v1/issues/#{issue_id}"), { token: jwt_token })
    nil unless response.status == 200

    JSON.parse response.body
  end

  def get_comment(issue_id, comment_id)
    # TODO
  end

  def create_comment!(issue_id, comment)
    # TODO
    response = @provider.post(URI.join(@url, "api/v1/issues/#{issue_id}/comments"), { token: jwt_token })
    # fire webhook to ops api that comment has been created
  end

  private

  def jwt_token
    # TODO: generate JWT
    ""
  end
end
