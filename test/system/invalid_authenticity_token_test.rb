require "application_system_test_case"

class InvalidAuthenticityTokenTest < ApplicationSystemTestCase
  setup do
    @allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @allow_forgery_protection
  end

  test "submitting a form with a stale token reloads the page with an alert" do
    issue = issues(:two)
    login_as users(:one)
    visit issue_path(issue)

    page.execute_script(<<~JS)
      document.querySelectorAll("input[name=authenticity_token]").forEach((input) => input.value = "stale")
      document.querySelector("meta[name=csrf-token]").content = "stale"
    JS
    find(".share-buttons .button-like").click

    assert_text "Platnosť stránky vypršala. Skúste to prosím znova."
    assert_current_path issue_path(issue)
    assert_equal 0, issue.reload.likes_count
  end
end
