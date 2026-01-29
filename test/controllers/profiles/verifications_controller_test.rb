require "test_helper"

class Profiles::VerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:non_full_access)
    login_user(@user)
  end

  test "enqueues SendVerificationCodeJob when requesting verification code" do
    phone_number = "+421123456789"

    assert_enqueued_with(job: Profiles::SendVerificationCodeJob, args: [ @user, phone_number ]) do
      patch profile_verification_path, params: { user: { phone_verification_number: phone_number } }
    end
  end

  private

  def login_user(user)
    post "/login", params: {
      email: user.email,
      password: "password"
    }
    follow_redirect!
  end
end
