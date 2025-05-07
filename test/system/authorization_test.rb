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

  private

  def verify_account
    perform_enqueued_jobs # run enqueued email deliveries
    email = ActionMailer::Base.deliveries.last

    verify_account_path = email.body.to_s[%r{(/verify-account\S+)}]

    visit verify_account_path

    click_on "Potvrdiť registráciu"
  end
end
