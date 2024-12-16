require "application_system_test_case"

class ApiIntegrationsTest < ApplicationSystemTestCase
  setup do
    @api_integration = api_integrations(:one)
  end

  test "visiting the index" do
    visit api_integrations_url
    assert_selector "h1", text: "Api integrations"
  end

  test "should create api integration" do
    visit api_integrations_url
    click_on "New api integration"

    fill_in "Api token public key", with: @api_integration.api_token_public_key
    fill_in "Name", with: @api_integration.name
    fill_in "Url", with: @api_integration.url
    fill_in "Webhook secret", with: @api_integration.webhook_private_key
    click_on "Create Api integration"

    assert_text "Api integration was successfully created"
    click_on "Back"
  end

  test "should update Api integration" do
    visit api_integration_url(@api_integration)
    click_on "Edit this api integration", match: :first

    fill_in "Api token public key", with: @api_integration.api_token_public_key
    fill_in "Name", with: @api_integration.name
    fill_in "Url", with: @api_integration.url
    fill_in "Webhook secret", with: @api_integration.webhook_private_key
    click_on "Update Api integration"

    assert_text "Api integration was successfully updated"
    click_on "Back"
  end

  test "should destroy Api integration" do
    visit api_integration_url(@api_integration)
    click_on "Destroy this api integration", match: :first

    assert_text "Api integration was successfully destroyed"
  end
end
