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

  def update_issue_status(issue_id, status)
    response = @provider.post(URI.join(@url, "api/v1/issues/#{issue_id}/status"), { status: status, token: jwt_token })
    raise unless response.status == 204
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
    JWT.encode({
        sub: @subject,
        exp: 5.minutes.from_now.to_i,
        jti: SecureRandom.uuid
      },
      @private_key,
      "ES256"
    )
  end
end
