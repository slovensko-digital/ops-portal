require "test_helper"

class Ai::PromptSnapshotTest < ActiveSupport::TestCase
  test "takes a snapshot unless the latest one of the prompt has the same content" do
    first = Ai::PromptSnapshot.take(content: "prompt v1", reason: "manual", note: "", author: users(:one))

    assert_equal [ "generatechecks", "manual", nil, users(:one) ], [ first.prompt_name, first.reason, first.note, first.author ]
    assert_nil Ai::PromptSnapshot.take(content: "prompt v1", reason: "auto")

    assert Ai::PromptSnapshot.take(content: "prompt v2", reason: "auto")
    assert Ai::PromptSnapshot.take(content: "prompt v1", reason: "revert")
    assert Ai::PromptSnapshot.take(content: "prompt v1", reason: "manual", prompt_name: "moderatecomments")
  end

  test "keeps only the newest automatic snapshots" do
    manual = Ai::PromptSnapshot.take(content: "manual", reason: "manual")
    oldest_auto = Ai::PromptSnapshot.take(content: "auto 0", reason: "auto")

    Ai::PromptSnapshot::AUTO_KEEP.times { Ai::PromptSnapshot.take(content: "auto #{it + 1}", reason: "auto") }

    assert_equal Ai::PromptSnapshot::AUTO_KEEP, Ai::PromptSnapshot.where(reason: "auto").count
    assert_not Ai::PromptSnapshot.exists?(oldest_auto.id)
    assert Ai::PromptSnapshot.exists?(manual.id)
  end

  test "rejects an unknown reason" do
    assert_raises(ActiveRecord::RecordInvalid) { Ai::PromptSnapshot.take(content: "prompt", reason: "other") }
  end
end
