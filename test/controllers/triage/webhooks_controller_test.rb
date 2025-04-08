require "test_helper"

class Triage::WebhooksControllerTest < ActionDispatch::IntegrationTest
  test "ticket-updated should receive 401 without x-hub-signature header" do
    post triage_webhooks_portal_url
    assert_response :unauthorized
  end

  test "ticket-updated should receive 400 with bad signature" do
    post triage_webhooks_portal_url, params: {}, headers: { "X-Hub-Signature": "sha1=sadfasdfas" }
    assert_response :forbidden
  end

  test "ticket-updated should successfully update existing issue" do
    # TODO: create real happy path test
    assert true
  end
end
