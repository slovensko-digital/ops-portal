require "application_system_test_case"

class Profiles::VerificationsTest < ApplicationSystemTestCase
  test "logged in user can request verification code with phone number" do
    user = users(:non_full_access)
    login_as(user)

    visit new_profile_verification_path

    assert_selector "h1", text: "Overenie totožnosti"
    assert_text "Aby ste mohli využívať všetky funkcie portálu"
    assert_text "Telefónne číslo sa použije len na toto overenie"

    # Record initial state
    initial_attempts = user.phone_verification_attempts

    fill_in "Telefónne číslo*", with: "+421123456789"

    click_button "Vyžiadať bezpečnostný kód"

    assert_current_path code_profile_verification_path

    # Verify record_phone_verification_attempt happened correctly
    user.reload

    # Check that phone_verification_attempts was incremented
    assert_equal initial_attempts + 1, user.phone_verification_attempts,
      "Phone verification attempts should be incremented (record_phone_verification_attempt was called)"

    # Check that phone_verification_attempted_at was set
    assert_not_nil user.phone_verification_attempted_at,
      "Phone verification attempt timestamp should be set (record_phone_verification_attempt was called)"
    assert user.phone_verification_attempted_at > 1.minute.ago,
      "Timestamp should be recent"

    # Check that phone_verification_code_attempts was reset to 0
    assert_equal 0, user.phone_verification_code_attempts,
      "Code attempts should be reset to 0 (record_phone_verification_attempt was called)"
  end
end
