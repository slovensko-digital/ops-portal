require "application_system_test_case"

class Issues::ActivityVotesTest < ApplicationSystemTestCase
  setup do
    @comment = issues_comments(:two_comment1)
    @comment.update_columns(text: "Komentár na hlasovanie")
    @activity = @comment.activity
  end

  test "user can like, switch to dislike and take the vote back" do
    login_as users(:legacy_citizen)
    visit issue_path(issues(:two))

    within "#voting_issues_comment_activity_#{@activity.id}" do
      assert_no_selector ".like[title]"
      find(".button-like").click
      assert_selector ".button-like.button-active", text: "1"
      assert_selector ".button-dislike:not(.button-active)", text: "0"
    end
    assert_equal 1, @activity.reload.likes_count

    within "#voting_issues_comment_activity_#{@activity.id}" do
      find(".button-dislike").click
      assert_selector ".button-dislike.button-active", text: "1"
      assert_selector ".button-like:not(.button-active)", text: "0"
    end
    @activity.reload
    assert_equal 0, @activity.likes_count
    assert_equal 1, @activity.dislikes_count
    assert_equal 1, @activity.votes.count, "one vote per user"

    within "#voting_issues_comment_activity_#{@activity.id}" do
      find(".button-dislike").click
      assert_selector ".button-dislike:not(.button-active)", text: "0"
    end
    assert_equal 0, @activity.reload.votes.count
  end

  test "author cannot vote on own comment" do
    login_as users(:one)
    visit issue_path(issues(:two))

    within "#voting_issues_comment_activity_#{@activity.id}" do
      assert_selector ".button-like[disabled]"
      assert_selector ".button-dislike[disabled]"
      assert_selector ".like[title='Vlastný príspevok nemôžete hodnotiť.']", count: 2
    end
  end
end
