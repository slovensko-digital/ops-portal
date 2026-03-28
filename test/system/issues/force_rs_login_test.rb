require "application_system_test_case"

class Issues::ForceRsLoginTest < ApplicationSystemTestCase
  setup do
    @issue = issues(:one)
    @rs_user = users(:responsible_subject)
  end

  test "visiting issue with force_rs_login redirects to login and back" do
    visit issue_path(@issue, force_rs_login: true)

    assert_current_path "/email-auth-request"
    assert_selector "h1", text: "Prihlásenie pre samosprávy"

    fill_in "Email", with: @rs_user.email
    click_on "Poslať prihlasovací odkaz"

    assert_text "Email s prihlasovacím odkazom bol odoslaný"

    link = email_link_from_last_delivery
    visit link
    click_button "Prihlásiť"

    assert_current_path issue_path(@issue)
  end

  test "visiting issue with force_rs_login when already logged in just cleans the URL" do
    login_via_magic_link(@rs_user.email)

    visit issue_path(@issue, force_rs_login: true)

    assert_current_path issue_path(@issue)
    assert_equal issue_path(@issue), URI.parse(current_url).path
    assert_nil URI.parse(current_url).query
  end

  private

  def email_link_from_last_delivery
    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    link = email.body.encoded.match(/href="([^"]+)"/)[1]
    link.sub(%r{http://example.com}, "")
  end
end
