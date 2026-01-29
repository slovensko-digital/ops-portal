require "application_system_test_case"
require "test_helpers/issues/drafts_helper"

class ProfilesTest < ApplicationSystemTestCase
  test "citizen user sees citizen profile" do
    @user = users(:one)
    login_as(@user)

    click_on "Jozef Mokry"

    assert_text "Moje podnety"
    assert_no_text "Legacy issue"

    click_on "Sledované podnety"

    assert_text "Legacy issue"
  end

  test "responsible subject user sees responsible subject profile" do
    @user = users(:responsible_subject)
    login_via_magic_link(@user.email)

    click_on "Mesto Nitra"

    assert_text "Profil samosprávy"
    assert_text "nitra@mesto.sk"

    assert_text "Odhlásiť sa"

    assert_no_text "Sledované podnety"
    assert_no_text "Moje podnety"
    assert_no_link "Upraviť profil"

    assert_no_selector ".profile-results-panel"
  end
end
