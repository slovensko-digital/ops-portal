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
    find('input[data-preferred-places-target="input"]').click
    find("label", exact_text: "Nitra").click

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
    assert_includes user.municipalities.pluck(:name), "Nitra"
    assert_equal true, user.email_notifiable
    assert_equal true, user.newsletter_accepted
    assert_equal true, user.gdpr_stats_accepted
  end

  test "citizen user sees preferred places as pills and can remove one" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path

    assert_selector "label", text: "Preferované mestá alebo obce (1)"
    find("button.filter-select-button", text: "Banská Bystrica").click

    assert_no_selector "button.filter-select-button"
    assert_selector "label", exact_text: "Preferované mestá alebo obce"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."
    assert_not_includes user.reload.municipalities.pluck(:name), "Banská Bystrica"
  end

  test "citizen user sees only the district name in a district pill" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    find('input[data-preferred-places-target="input"]').fill_in(with: "Petržalka")
    find("label", exact_text: "Petržalka").click

    assert_selector "button.filter-select-button[title='Odstrániť: Bratislava - Petržalka']", exact_text: "Petržalka"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."
    assert_includes user.reload.municipality_districts.pluck(:name), "Petržalka"
  end

  test "citizen user selecting a municipality ticks its districts but saves only the municipality" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    find('input[data-preferred-places-target="input"]').fill_in(with: "Spišská Nová Ves")
    find("label", exact_text: "Spišská Nová Ves").click

    assert_selector "li.district.active", count: 7
    assert_selector "button.filter-select-button", exact_text: "Spišská Nová Ves"
    assert_no_selector "button.filter-select-button", text: "Ferčekovce"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."
    assert_includes user.reload.municipalities.pluck(:name), "Spišská Nová Ves"
    assert_empty user.municipality_districts
  end

  test "citizen user unticking a district of a selected municipality keeps the other districts" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    find('input[data-preferred-places-target="input"]').fill_in(with: "Banská Bystrica")
    find("label", exact_text: "Centrum").click

    assert_selector "li.partial", exact_text: "Banská Bystrica"
    assert_no_selector "button.filter-select-button", exact_text: "Banská Bystrica"
    assert_selector "button.filter-select-button", count: 6

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."
    user.reload
    assert_not_includes user.municipalities.pluck(:name), "Banská Bystrica"
    assert_equal 6, user.municipality_districts.count
    assert_not_includes user.municipality_districts.pluck(:name), "Centrum"
  end

  test "citizen user ticking every district of a municipality selects the whole municipality" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    find('input[data-preferred-places-target="input"]').fill_in(with: "Spišská Nová Ves")
    district_labels = all("li.district label", count: 7)
    district_labels.each(&:click)

    assert_selector "li.active:not(.district)", exact_text: "Spišská Nová Ves"
    assert_no_selector "li.partial"
    assert_selector "button.filter-select-button", exact_text: "Spišská Nová Ves"
    assert_no_selector "button.filter-select-button", text: "Ferčekovce"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."
    assert_includes user.reload.municipalities.pluck(:name), "Spišská Nová Ves"
    assert_empty user.municipality_districts
  end

  test "citizen user sees a message when no preferred place matches the search" do
    login_as(users(:one))

    visit edit_profile_path
    input = find('input[data-preferred-places-target="input"]')
    input.fill_in(with: "xyzq")

    assert_text "Nič sme nenašli."

    input.send_keys(:escape)

    assert_no_text "Nič sme nenašli."
    assert_equal "", input.value
  end

  test "responsible subject user can't update profile" do
    user = users(:responsible_subject)
    login_via_magic_link(user.email)

    visit edit_profile_path

    assert_text "Túto akciu nemôžete vykonať."
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

  test "citizen user sees an error when the new profile picture is not an image" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"
    assert_selector "input[name='user[avatar]'][accept='image/*']", visible: :all

    page.attach_file("user[avatar]", file_fixture("responsible_subject_emails/ivanka_expected.txt"), make_visible: true)

    assert_text "Profilová fotka môže byť iba obrázok."
    assert_not user.reload.avatar.attached?
  end

  test "citizen user sees an error when the new profile picture cannot be read" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    page.attach_file("user[avatar]", file_fixture("not-an-image.png"), make_visible: true)

    assert_text "Profilová fotka môže byť iba obrázok."
    assert_not user.reload.avatar.attached?
  end

  test "citizen user can remove profile picture" do
    user = users(:one)
    user.avatar.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    login_as(user)

    visit edit_profile_path
    accept_confirm { click_button "Odstrániť fotku" }

    assert_text "Fotka bola odstránená."
    assert_no_button "Odstrániť fotku"
    assert_not user.reload.avatar.attached?
  end

  test "citizen user without profile picture does not see the remove button" do
    login_as(users(:one))

    visit edit_profile_path

    assert_selector "h1", text: "Osobné údaje"
    assert_no_button "Odstrániť fotku"
  end
end
