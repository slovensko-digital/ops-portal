require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate terms_of_service acceptance on onboarding" do
    user = users(:one)
    user.terms_of_service = false

    assert_not user.valid?(:onboarding), "User should be invalid without accepting terms of service during onboarding"

    user.terms_of_service = true
    assert user.valid?(:onboarding), "User should be valid when terms of service is accepted during onboarding"
  end

  test "should validate phone verification number format" do
    user = users(:one)

    invalid_formats = [ "123456789", "+12345", "1234567890" ]
    invalid_formats.each do |format|
      user.phone_verification_number = format
      assert_not user.valid?(:phone_verification)
    end

    user.phone_verification_number = "+421123456789"
    assert user.valid?(:phone_verification)
  end

  test "should limit phone verification attempts" do
    user = users(:one)
    user.phone_verification_number = "+421123456789"

    # Set attempted time to recent
    user.phone_verification_attempted_at = Time.current - 30.minutes

    # Test with max attempts
    user.phone_verification_attempts = 5
    assert_not user.valid?(:phone_verification), "Should reject after too many recent attempts"

    # Test with fewer attempts
    user.phone_verification_attempts = 4
    assert user.valid?(:phone_verification), "Should allow with fewer attempts"

    # Test with old attempts (more than 1 hour ago)
    user.phone_verification_attempted_at = Time.current - 2.hours
    user.phone_verification_attempts = 10
    assert user.valid?(:phone_verification), "Should allow when attempts are old"
  end

  test "should validate phone verification code confirmation" do
    user = users(:one)
    user.phone_verification_code = "12345"

    user.phone_verification_code_confirmation = nil
    assert_not user.valid?(:phone_verification_code)

    user.phone_verification_code_confirmation = "54321"
    assert_not user.valid?(:phone_verification_code)

    user.phone_verification_code_confirmation = "12345"
    assert user.valid?(:phone_verification_code)
  end

  test "should limit phone verification code attempts" do
    user = users(:one)
    user.phone_verification_code = "12345"
    user.phone_verification_code_confirmation = "12345"

    # Test with max attempts
    user.phone_verification_code_attempts = 10
    assert_not user.valid?(:phone_verification_code), "Should reject after too many code attempts"

    # Test with fewer attempts
    user.phone_verification_code_attempts = 9
    assert user.valid?(:phone_verification_code), "Should allow with fewer code attempts"
  end
end
