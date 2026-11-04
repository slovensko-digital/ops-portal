require "application_system_test_case"

class IssueSharingTest < ApplicationSystemTestCase
  test "a public issue can be shared" do
    login_as users(:one)
    visit issue_path(issues(:two))

    assert_selector ".share-buttons .button-share-desktop"
  end

  test "the author of a rejected issue sees no like or share buttons" do
    issue = issues(:two)
    issue.update_columns(state_id: issues_states(:rejected).id)
    login_as users(:one)

    visit issue_path(issue)

    assert_selector "h1", text: issue.title
    assert_no_selector ".share-buttons .button-like"
    assert_no_selector ".share-buttons .button-share-desktop"
  end
end
