require "application_system_test_case"

class BackofficeClientsTest < ApplicationSystemTestCase
  setup do
    @backoffice_client = backoffice_clients(:one)
  end

  test "visiting the index" do
    visit backoffice_clients_url
    assert_selector "h1", text: "Backoffice clients"
  end

  test "should create backoffice client" do
    visit backoffice_clients_url
    click_on "New backoffice client"

    fill_in "Api token public key", with: @backoffice_client.api_token_public_key
    fill_in "Name", with: @backoffice_client.name
    fill_in "Url", with: @backoffice_client.url
    fill_in "Webhook secret", with: @backoffice_client.webhook_private_key
    click_on "Create Backoffice client"

    assert_text "Backoffice client was successfully created"
    click_on "Back"
  end

  test "should update Backoffice client" do
    visit backoffice_client_url(@backoffice_client)
    click_on "Edit this backoffice client", match: :first

    fill_in "Api token public key", with: @backoffice_client.api_token_public_key
    fill_in "Name", with: @backoffice_client.name
    fill_in "Url", with: @backoffice_client.url
    fill_in "Webhook secret", with: @backoffice_client.webhook_private_key
    click_on "Update Backoffice client"

    assert_text "Backoffice client was successfully updated"
    click_on "Back"
  end

  test "should destroy Backoffice client" do
    visit backoffice_client_url(@backoffice_client)
    click_on "Destroy this backoffice client", match: :first

    assert_text "Backoffice client was successfully destroyed"
  end
end
