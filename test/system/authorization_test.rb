require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "creating an account with email verification" do
    visit "/create-account"
    assert_selector "h1", text: "Vytvoriť účet"

    click_button "Vytvoriť účet"

    assert_selector ".flash-message-container", text: "Pri vytváraní účtu nastala chyba."

    fill_in "Email", with: "new-account@example.com"
    fill_in "Heslo", with: "Very_secret_123", match: :first
    fill_in "Heslo (znova)", with: "Very_secret_123"

    fill_in "Meno", with: "Jozef"

    click_button "Vytvoriť účet"

    assert_selector ".flash-message-container", text: "Zaslali sme Vám email odkazom na overenie účtu"

    verify_account
  end

  test "login" do
    user = users(:one)

    visit root_path

    assert_selector "a.login", text: "Prihlásiť"

    login(user.email, "password")

    assert_selector "a.login", text: user.firstname
  end

  test "logout" do
    login(users(:one).email, "password")

    logout

    assert_selector "a.login", text: "Prihlásiť"
  end

  test "banned user cannot login" do
    user = users(:one)
    user.update!(banned: true)

    visit "/login"

    fill_in "Email", with: user.email
    fill_in "Heslo", with: "password"

    click_button "Prihlásiť"

    assert_selector ".flash-message-container", text: "Váš účet bol zablokovaný."
    assert_selector "a.login", text: "Prihlásiť"
  end

  test "banned user gets logged out if already logged in" do
    user = users(:one)

    login(user.email, "password")
    assert_selector "a.login", text: user.firstname

    user.update!(banned: true)

    visit root_path

    assert_selector ".flash-message-container", text: "Váš účet bol zablokovaný."
    assert_selector "a.login", text: "Prihlásiť"
  end

  test "citizen user can login via email (magic link)" do
    user = users(:one)

    visit "/login"
    click_on "Prihlásiť sa cez email"

    assert_selector "h1", text: "Prihlásenie bez hesla"

    fill_in "Email", with: user.email
    click_on "Poslať prihlasovací odkaz"

    assert_text "Email s prihlasovacím odkazom bol odoslaný."

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal [ user.email ], email.to
    assert_match(/Prihlásenie do profilu/, email.subject)

    link = email.body.encoded.match(/href="([^"]+)"/)[1]
    link = link.sub(%r{http://example.com}, "")

    visit link

    assert_selector "h1", text: "Dokončiť prihlásenie"
    click_on "Vstúpiť do portálu"

    assert_text "Prihlásenie bolo úspešné"
    assert_selector "a.login", text: user.firstname
  end

  test "login via email with invalid link" do
    user = users(:one)

    visit "/login"
    click_on "Prihlásiť sa cez email"

    assert_selector "h1", text: "Prihlásenie bez hesla"

    fill_in "Email", with: user.email
    click_on "Poslať prihlasovací odkaz"

    assert_text "Email s prihlasovacím odkazom bol odoslaný."

    visit "/email-auth?key=invalid_key"

    assert_text "Neplatný, expirovaný alebo už použitý prihlasovací odkaz."
    assert_selector "h1", text: "Prihlásenie"
  end

  test "responsible subject user cannot login via password" do
    user = users(:responsible_subject)

    visit "/login"
    fill_in "Email", with: user.email
    fill_in "Heslo", with: "password"
    click_button "Prihlásiť"

    assert_text "Pre tento účet je povolené prihlásenie iba cez email."
    assert_selector "a.login", text: "Prihlásiť"
  end

  test "responsible subject user can login via email (magic link)" do
    user = users(:responsible_subject)

    visit "/login"
    click_on "Prihlásiť sa cez email"

    assert_selector "h1", text: "Prihlásenie bez hesla"

    fill_in "Email", with: user.email
    click_on "Poslať prihlasovací odkaz"

    assert_text "Email s prihlasovacím odkazom bol odoslaný."

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_equal [ user.email ], email.to
    assert_match(/Prihlásenie do profilu/, email.subject)

    link = email.body.encoded.match(/href="([^"]+)"/)[1]
    link = link.sub(%r{http://example.com}, "")

    visit link
    assert_selector "h1", text: "Dokončiť prihlásenie"
    click_on "Vstúpiť do portálu"

    assert_text "Prihlásenie bolo úspešné"
    assert_selector "a.login", text: user.firstname
  end

  private

  def verify_account
    perform_enqueued_jobs # run enqueued email deliveries
    email = ActionMailer::Base.deliveries.last

    verify_account_path = email.body.to_s.match(/(\/verify-account\S+)"/).captures[0]

    visit verify_account_path

    click_on "Potvrdiť registráciu"
  end
end
