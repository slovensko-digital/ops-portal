require "application_system_test_case"

class Issues::UserCommentsTest < ApplicationSystemTestCase
  test "user has to be logged in to add comment to issue discussion" do
    visit issue_path(issues(:legacy1))

    assert_text "Chcete pridať komentár alebo overiť podnet? Prihláste sa!"
  end

  test "logged in user can add comment to issue discussion" do
    logged_in_user = users(:one)

    login(logged_in_user.email, "password")

    visit issue_path(issues(:legacy1))

    assert_text "Pridať komentár"

    click_on "Pridať komentár"

    fill_in "issues_user_private_comment_text", with: "Nový komentár. :)"

    click_on "Odoslať"

    within "#activities" do
      assert_text logged_in_user.display_name
      assert_text "Nový komentár. :)"
      assert_text "Upraviť"
    end
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

  test "comment hidden by AI moderation shows the reason instead of its text" do
    comment = issues_comments(:two_comment1)
    comment.update!(text: "test comment", hidden: true, ai_evaluation: { "overall_score" => 0.95, "reason" => "Komentár obsahuje urážku." })

    visit issue_path(comment.issue)

    within "#komentar_#{comment.id}" do
      assert_text "Tento komentár bol skrytý.\nDôvod: Komentár obsahuje urážku."
      assert_no_text "test comment"
    end
  end

  test "comment hidden in triage shows no reason" do
    comment = issues_comments(:two_comment1)
    comment.update!(text: "test comment", hidden: true, ai_evaluation: { "overall_score" => 0.1, "reason" => "Komentár je v poriadku." })

    visit issue_path(comment.issue)

    within "#komentar_#{comment.id}" do
      assert_text "Tento komentár bol skrytý."
      assert_no_text "Dôvod"
    end
  end
end
