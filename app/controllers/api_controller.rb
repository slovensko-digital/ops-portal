class ApiController < ActionController::API
  before_action :set_zammad_client
  before_action :default_format_json

  private

  def set_zammad_client
    @zammad_client = TriageZammadEnvironment.client
  end

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish&.presence
  end

  def authenticate_client
    # TODO
    @client = ApiEnvironment.token_authenticator.verify_token(authenticity_token)
  end

  def default_format_json
    request.format = "json"
  end
end
