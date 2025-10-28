class ApiController < ActionController::API
  before_action :set_zammad_client

  rescue_from JWT::DecodeError do |error|
    if error.message == "Nil JSON web token"
      render_bad_request(RuntimeError.new(:no_credentials))
    else
      render_unauthorized(error.message)
    end
  end

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ArgumentError, with: :render_unprocessable_entity

  private

  def set_zammad_client
    @zammad_client = TriageZammadEnvironment.client
  end

  def authenticity_token
    (ActionController::HttpAuthentication::Token.token_and_options(request)&.first || params[:token])&.squish&.presence
  end

  def authenticate_client
    @client = ApiEnvironment.token_authenticator.verify_token(authenticity_token)
  end

  def render_bad_request(exception)
    render status: :bad_request, json: { message: exception.message }
  end

  def render_unauthorized(key = "credentials")
    headers["WWW-Authenticate"] = 'Token realm="API"'
    render status: :unauthorized, json: { message: "Unauthorized " + key }
  end

  def render_not_found(_key = nil, **_options)
    render status: :not_found, json: { message: "Not found" }
  end

  def render_unprocessable_entity(message)
    render status: :unprocessable_entity, json: { message: message }
  end
end
