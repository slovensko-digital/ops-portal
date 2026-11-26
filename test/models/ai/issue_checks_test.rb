require "test_helper"

class Ai::IssueChecksTest < ActiveSupport::TestCase
  test "lists the check titles of the prompt's checks dictionary" do
    prompt = <<~PROMPT
      Return all failing checks.

      Title: Parkovanie
      Info: Nahláste priamo.

      Title:  Vrak#{"  "}
      Title: Parkovanie
    PROMPT

    assert_equal %w[Parkovanie Vrak], Ai::IssueChecks.titles_in(prompt)
  end
end
