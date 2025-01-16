require "application_system_test_case"

class ClientsTest < ApplicationSystemTestCase
  setup do
    @client = clients(:one)
  end

  test "visiting the index" do
    visit clients_url
    assert_selector "h1", text: "Clients"
  end

  test "should create client" do
    visit clients_url
    click_on "New client"

    fill_in "Api token public key", with: @client.api_token_public_key
    fill_in "Name", with: @client.name
    fill_in "Url", with: @client.url
    fill_in "Webhook private key", with: @client.webhook_private_key
    click_on "Create Client"

    assert_text "Client was successfully created"
    click_on "Back"
  end

  test "should update client" do
    visit client_url(@client)
    click_on "Edit this client", match: :first

    fill_in "Api token public key", with: @client.api_token_public_key
    fill_in "Name", with: @client.name
    fill_in "Url", with: @client.url
    fill_in "Webhook private key", with: @client.webhook_private_key
    click_on "Update Client"

    assert_text "Client was successfully updated"
    click_on "Back"
  end

  test "should destroy Client" do
    visit client_url(@client)
    click_on "Destroy this client", match: :first

    assert_text "Client was successfully destroyed"
  end
end
