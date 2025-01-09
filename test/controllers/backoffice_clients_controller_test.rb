require "test_helper"

class BackofficeClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @backoffice_client = backoffice_clients(:one)
  end

  test "should get index" do
    get backoffice_clients_url
    assert_response :success
  end

  test "should get new" do
    get new_backoffice_client_url
    assert_response :success
  end

  test "should create backoffice_client" do
    assert_difference("BackofficeClient.count") do
      post backoffice_clients_url, params: {
        backoffice_client: {
          api_token_public_key: @backoffice_client.api_token_public_key,
          name: @backoffice_client.name,
          url: @backoffice_client.url,
          webhook_private_key: @backoffice_client.webhook_private_key,
          responsible_subject_zammad_identifier: @backoffice_client.responsible_subject_zammad_identifier
          }
        }
    end

    assert_redirected_to backoffice_client_url(BackofficeClient.last)
  end

  test "should show backoffice_client" do
    get backoffice_client_url(@backoffice_client)
    assert_response :success
  end

  test "should get edit" do
    get edit_backoffice_client_url(@backoffice_client)
    assert_response :success
  end

  test "should update backoffice_client" do
    patch backoffice_client_url(@backoffice_client), params: {
      backoffice_client: {
        api_token_public_key: @backoffice_client.api_token_public_key,
        name: @backoffice_client.name,
        url: @backoffice_client.url,
        webhook_private_key: @backoffice_client.webhook_private_key,
        responsible_subject_zammad_identifier: @backoffice_client.responsible_subject_zammad_identifier
        }
      }
    assert_redirected_to backoffice_client_url(@backoffice_client)
  end

  test "should destroy backoffice_client" do
    assert_difference("BackofficeClient.count", -1) do
      delete backoffice_client_url(@backoffice_client)
    end

    assert_redirected_to backoffice_clients_url
  end
end
