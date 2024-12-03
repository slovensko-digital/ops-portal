class OvmConnector::OpsApiClient
  def initialize(tenant, url: ENV.fetch("CONNECTOR__OPS_API_URL"))
    @subject = tenant.api_subject_identifier
    @private_key = OpenSSL::PKey::EC.new(tenant.api_token_private_key)
    @url = url
  end

  def get_issue
    # TODO
  end

  def get_comment
    # TODO
  end

  private

  def jwt_token
    # TODO: generate JWT
  end
end
