require "application_system_test_case"

class IssuePreviewTest < ApplicationSystemTestCase
  test "anyone with the triage preview link sees a hidden issue read-only" do
    issue = issues(:one)

    visit preview_path(issue)

    assert_selector ".issue-preview-notice", text: "Náhľad"
    assert_selector "h1", text: "Rozbitá lavička na námestí"
    assert_no_selector ".share-buttons .button-like"
    assert_no_selector ".share-buttons .button-share"
    assert_no_button "Upraviť"
    assert_no_text "Chcete pridať komentár alebo overiť podnet?"
  end

  test "the discussion is shown in the preview without any actions" do
    issue = issues(:one)

    visit preview_path(issue)

    within ".podnet-discussion" do
      assert_selector ".comment"
      assert_selector ".button-like[disabled]"
      assert_selector ".button-dislike[disabled]"
      assert_no_selector ".button-share:not([disabled])"
      assert_no_link "Upraviť"
    end
  end

  test "a hidden praise is shown read-only with the preview link" do
    visit preview_path(issues(:praise_waiting))

    assert_selector ".issue-preview-notice", text: "Náhľad"
    assert_selector "h1", text: "Bike lanes are wide and safety"
    assert_no_selector ".compliment-buttons-con"
  end

  test "the author sees their own hidden issue without the preview notice" do
    issue = issues(:one)
    login_as users(:one)

    visit preview_path(issue)

    assert_no_selector ".issue-preview-notice"
    assert_selector ".share-buttons .button-edit"
  end

  private

  def preview_path(issue)
    issue_path(issue, nahlad: IssuePreviewSigner.token(issue))
  end
end
