require "test_helper"

class ApiIntegrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_integration = api_integrations(:one)
  end

  test "should get index" do
    get api_integrations_url
    assert_response :success
  end

  test "should get new" do
    get new_api_integration_url
    assert_response :success
  end

  test "should create api_integration" do
    assert_difference("ApiIntegration.count") do
      post api_integrations_url, params: {
        api_integration: {
          api_token_public_key: @api_integration.api_token_public_key,
          name: @api_integration.name,
          url: @api_integration.url,
          webhook_private_key: @api_integration.webhook_private_key,
          responsible_subject_zammad_identifier: @api_integration.responsible_subject_zammad_identifier
          }
        }
    end

    assert_redirected_to api_integration_url(ApiIntegration.last)
  end

  test "should show api_integration" do
    get api_integration_url(@api_integration)
    assert_response :success
  end

  test "should get edit" do
    get edit_api_integration_url(@api_integration)
    assert_response :success
  end

  test "should update api_integration" do
    patch api_integration_url(@api_integration), params: {
      api_integration: {
        api_token_public_key: @api_integration.api_token_public_key,
        name: @api_integration.name,
        url: @api_integration.url,
        webhook_private_key: @api_integration.webhook_private_key,
        responsible_subject_zammad_identifier: @api_integration.responsible_subject_zammad_identifier
        }
      }
    assert_redirected_to api_integration_url(@api_integration)
  end

  test "should destroy api_integration" do
    assert_difference("ApiIntegration.count", -1) do
      delete api_integration_url(@api_integration)
    end

    assert_redirected_to api_integrations_url
  end
end
