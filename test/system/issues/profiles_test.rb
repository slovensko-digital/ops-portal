require "application_system_test_case"
require "test_helpers/issues/drafts_helper"

class ProfilesTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "user sees profile" do
    login_as(@user)

    click_on "Jozef Mokry"

    assert_text "Moje podnety"
    assert_no_text "Legacy issue"

    click_on "Sledované podnety"

    assert_text "Legacy issue"
  end
end
