class ApiController < ActionController::API
  before_action :default_format_json

  private

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
