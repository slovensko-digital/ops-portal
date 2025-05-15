require "application_system_test_case"

class IssuesTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit issues_path
    assert_selector "h1", text: "Nahlásené dopyty"

    within ".podnety-con" do
      assert_text "Legacy issue"
      assert_text "Issue from Bratislava"
      assert_text "Finally cleaned"
    end
  end

  test "user has to be logged in to add comment to issue discussion" do
    visit issue_path(issues(:legacy1))

    assert_text "Chcete pridať komentár alebo overiť podnet? Prihláste sa!"
  end

  test "logged in user can add comment to issue discussion" do
    login(users(:one).email, "password")

    visit issue_path(issues(:legacy1))

    assert_text "Pridať komentár"
  end

  test "discussion closed info not showed unless user logged in" do
    visit issue_path(issues(:legacy_discussion_closed))

    assert_text "Chcete pridať komentár alebo overiť podnet? Prihláste sa!"
    assert_no_text "Diskusia k tomuto podnetu bola uzatvorená"
  end

  test "not even logged in user can add comment to issue discussion if discussion closed" do
    login(users(:one).email, "password")

    visit issue_path(issues(:legacy_discussion_closed))

    assert_text "Diskusia k tomuto podnetu bola uzatvorená"
    assert_no_text "Pridať komentár"
  end

  test "published praise" do
    visit issue_path(issues(:praise_published))

    assert_selector "h1", text: "Finally cleaned"
    assert_text "Very good!"
  end
end
