require "test_helper"

class RodauthControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "create account creates citizen" do
    email = "user-#{SecureRandom.hex(4)}@example.com"

    assert_enqueued_emails 1 do
      assert_difference("User.count", 1) do
        post "/create-account", params: {
          email: email,
          password: "Very_secret_123",
          "password-confirm": "Very_secret_123",
          name: "new-user-#{SecureRandom.hex(4)}",
        }
      end
    end

    assert_response :redirect

    user = User.find_by!(email: email)
    assert_equal "User::Citizen", user.type
    assert user.unverified?
    assert user.email_global_unsubscribe_token.present?
  end
end

