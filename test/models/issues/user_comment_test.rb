require "test_helper"

class Issues::UserCommentTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @issue = issues(:one)
    @comment = Issues::UserComment.new(
      user_author: @user,
      text: "This is a test comment"
    )
    @comment.build_activity(issue: @issue, type: Issues::CommentActivity)
    @comment.save!
  end

  test "should be valid within editing window" do
    assert @comment.within_editing_window?

    assert @comment.valid?(:edit)
  end

  test "should not be valid outside editing window" do
    @comment.update_column(:created_at, 6.minutes.ago)

    # Verify it's outside the window
    assert_not @comment.within_editing_window?

    assert_not @comment.valid?(:edit)
    assert_includes @comment.errors[:base], "Komentár je možné upravovať len 5 minút od jeho vytvorenia."
  end

  test "editable_by? returns true for author within editing window" do
    assert @comment.editable_by?(@user)
  end

  test "editable_by? returns false for author outside editing window" do
    @comment.update_column(:created_at, 6.minutes.ago)

    assert_not @comment.editable_by?(@user)
  end

  test "editable_by? returns false for non-author" do
    another_user = users(:two) # Assuming you have another user fixture

    assert_not @comment.editable_by?(another_user)
  end

  test "editable_by? returns false for nil user" do
    assert_not @comment.editable_by?(nil)
  end
end
