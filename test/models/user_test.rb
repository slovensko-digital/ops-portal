require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate terms_of_service acceptance on onboarding" do
    user = users(:one)
    user.terms_of_service = false

    assert_not user.valid?(:onboarding), "User should be invalid without accepting terms of service during onboarding"

    user.terms_of_service = true
    assert user.valid?(:onboarding), "User should be valid when terms of service is accepted during onboarding"
  end
end
