class ApiController < ActionController::API
  before_action :default_format_json

  private

  def authenticate_backoffice_client
    # @backoffice_client = nil
    @backoffice_client = BackofficeClient.first
  end

  def default_format_json
    request.format = "json"
  end
end
