class ApiController < ActionController::API
  before_action :default_format_json

  private

  def authenticate_integration
    # @api_integration = nil
    @api_integration = ApiIntegration.first
  end

  def default_format_json
    request.format = "json"
  end
end
