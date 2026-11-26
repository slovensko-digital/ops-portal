require "test_helper"

class IssuePreviewSignerTest < ActiveSupport::TestCase
  test "url points to the issue with its token" do
    issue = issues(:one)

    assert_equal "http://localhost:3000/dopyty/#{issue.id}?nahlad=#{IssuePreviewSigner.token(issue)}", IssuePreviewSigner.url(issue)
  end

  test "token is stable and short" do
    issue = issues(:one)

    assert_equal IssuePreviewSigner.token(issue), IssuePreviewSigner.token(issue)
    assert_equal 20, IssuePreviewSigner.token(issue).length
  end

  test "valid? accepts the issue's own token only" do
    issue = issues(:one)

    assert IssuePreviewSigner.valid?(issue, IssuePreviewSigner.token(issue))
    assert_not IssuePreviewSigner.valid?(issue, IssuePreviewSigner.token(issues(:two)))
    assert_not IssuePreviewSigner.valid?(issue, nil)
    assert_not IssuePreviewSigner.valid?(issue, "")
    assert_not IssuePreviewSigner.valid?(issue, [ "x" ])
  end

  test "token depends on the secret" do
    issue = issues(:one)
    token = IssuePreviewSigner.token(issue)

    with_env("ISSUE_PREVIEW_SECRET" => "rotated") do
      assert_not IssuePreviewSigner.valid?(issue, token)
    end
  end

  private

  def with_env(vars)
    original = vars.keys.index_with { |k| ENV[k] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    original.each { |k, v| ENV[k] = v }
  end
end
