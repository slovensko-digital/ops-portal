require "test_helper"

class Issues::Drafts::ChecksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    post "/login", params: { email: @user.email, password: "password" }

    # e.g. submitted from a summary page opened before the category was removed or never set
    @draft = Issues::Draft.create!(
      author: @user, latitude: 48.16, longitude: 17.05, picked_suggestion_index: 0, checks: [],
      title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit"
    )
  end

  test "submitting a draft without a category redirects to the summary" do
    assert_no_difference -> { Issue.count } do
      post issues_draft_checks_path(@draft)
    end

    assert_redirected_to issues_draft_summary_path(@draft)
  end

  test "confirming a draft without a category redirects to the summary" do
    assert_no_difference -> { Issue.count } do
      post confirm_issues_draft_checks_path(@draft)
    end

    assert_redirected_to issues_draft_summary_path(@draft)
  end
end
