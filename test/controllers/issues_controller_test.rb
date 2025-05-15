require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @issue = issues(:two)
  end

  test "should get search index" do
    get issues_url
    assert_response :success
  end

  test "should get search with pin" do
    get issues_url(pin: "48.16430806895233,17.051006812727774")
    assert_response :success
  end

  test "should get stats index" do
    get issues_url(tab: :stats)
    assert_response :success
  end

  test "should show issue" do
    get issue_url(@issue)
    assert_response :success
  end

  test "should not show resolved_private issues" do
    get issue_url(issues(:resolved_private))
    assert_response :not_found
  end
end
