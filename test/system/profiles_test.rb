require "application_system_test_case"

class ProfilesTest < ApplicationSystemTestCase
  test "citizen user can update profile name and birth year" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"

    fill_in "Meno*", with: "Updated Citizen Name"
    fill_in "Rok narodenia", with: "1990"

    # Set anonymous mode (choosing 'Nie' means anonymous = true)
    choose "user_anonymous_true"

    # Select municipality
    select "Nitra", from: "municipality_id"

    # Set email notifications
    choose "user_email_notifiable_true"

    # Check newsletter
    check "user_newsletter_accepted"

    # Check GDPR stats
    check "user_gdpr_stats_accepted"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."

    user.reload
    assert_equal "Updated Citizen Name", user.name
    assert_equal 1990, user.birth_year
    assert_equal true, user.anonymous
    assert_equal Municipality.find_by(name: "Nitra").id, user.municipality_id
    assert_equal true, user.email_notifiable
    assert_equal true, user.newsletter_accepted
    assert_equal true, user.gdpr_stats_accepted
  end

  test "responsible subject user can update profile name and birth year" do
    user = users(:responsible_subject)
    login_via_magic_link(user.email)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"

    fill_in "Meno*", with: "Updated RS Name"
    fill_in "Rok narodenia", with: "2010"

    # Set public profile (choosing 'false' means not anonymous)
    choose "user_anonymous_false"

    # Select municipality
    select "Bratislava", from: "municipality_id"

    # Disable email notifications
    choose "user_email_notifiable_false"

    # Uncheck newsletter
    uncheck "user_newsletter_accepted"

    # Check GDPR stats
    check "user_gdpr_stats_accepted"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."

    user.reload
    assert_equal "Updated RS Name", user.name
    assert_equal 2010, user.birth_year
    assert_equal false, user.anonymous
    assert_equal Municipality.find_by(name: "Bratislava").id, user.municipality_id
    assert_equal false, user.email_notifiable
    assert_equal false, user.newsletter_accepted
    assert_equal true, user.gdpr_stats_accepted
  end

  test "citizen user requires login to access profile edit" do
    visit edit_profile_path

    # Should redirect to login
    assert_text "a byť prihlásený"
  end

  test "citizen user can change profile picture" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"

    # Verify user doesn't have an avatar initially
    assert_not user.avatar.attached?

    # Attach a test image via the hidden file field (triggered by "Zmeniť fotku" button)
    page.attach_file("user[avatar]", Rails.root.join("test/fixtures/files/avatar.png"), make_visible: true)

    # Wait for auto-submit to complete
    sleep 1

    # Verify the avatar was attached
    user.reload
    assert user.avatar.attached?
    assert_equal "avatar.png", user.avatar.filename.to_s
  end
end
