require "test_helper"
require "test_helpers/request_helper"

class Ai::PromptTestCaseTest < ActiveSupport::TestCase
  include RequestHelper

  setup do
    @gemini_url = %r{generativelanguage\.googleapis\.com/v1beta/models/gemini-2\.5-pro:generateContent}
  end

  teardown do
    WebMock.reset!
  end

  test "splits expected check titles given one per line and drops blanks and duplicates" do
    test_case = Ai::PromptTestCase.new(expected_check_titles: [ "Parkovanie", "", "Vrak\r\n Parkovanie \n" ])

    assert_equal %w[Parkovanie Vrak], test_case.expected_check_titles
  end

  test "runs the case with the given prompt and model and passes when the returned checks match" do
    request_body = nil
    stub_request(:post, @gemini_url)
      .with { request_body = JSON.parse(it.body) }
      .to_return(body: file_fixture("webmock/gemini/checks-parking.json").read, headers: { "Content-Type" => "application/json" })

    result = ai_prompt_test_cases(:parking).run(prompt: "edited prompt", model: "gemini-2.5-pro")

    assert result.passed?(%w[Parkovanie])
    assert_equal "gemini-2.5-pro", result.model
    assert_in_delta (2000 * 1.25 + 200 * 10.0) / 1_000_000, result.cost
    assert_equal "edited prompt", request_body.dig("system_instruction", "parts", 0, "text")
    assert_equal(
      { "title" => "Auto na chodníku", "description" => "Pred domom už týždeň parkuje auto na chodníku.", "address" => "Banská Bystrica, Hlavná 1" },
      JSON.parse(request_body.dig("contents", 0, "parts", 0, "text"))
    )
  end

  test "replaces the categories placeholder in the edited prompt like production does" do
    request_body = nil
    stub_request(:post, @gemini_url)
      .with { request_body = JSON.parse(it.body) }
      .to_return(body: file_fixture("webmock/gemini/checks-empty.json").read, headers: { "Content-Type" => "application/json" })

    ai_prompt_test_cases(:pothole).run(prompt: "Categories:\n{{ CATEGORIES_TABLE }}", model: "gemini-2.5-pro")

    assert_includes request_body.dig("system_instruction", "parts", 0, "text"), "| category | subcategory | subtype |"
  end

  test "fails and lists missing and unexpected checks when they differ from the expected ones" do
    stub_json_request(:post, @gemini_url, response: "webmock/gemini/checks-parking.json")

    result = ai_prompt_test_cases(:pothole).run(prompt: "prompt", model: "gemini-2.5-pro")

    assert_not result.passed?([])
    assert_not result.passed?(%w[Vrak])
    assert_equal %w[Vrak], result.missing_titles(%w[Vrak])
    assert_equal %w[Parkovanie], result.unexpected_titles(%w[Vrak])
  end

  test "returns the error instead of raising when Gemini fails" do
    stub_request(:post, @gemini_url).to_return(status: 400, body: "API key not valid")

    result = ai_prompt_test_cases(:pothole).run(prompt: "prompt", model: "gemini-2.5-pro")

    assert_equal "Gemini API returned status 400", result.error
    assert_not result.passed?([])
  end

  test "the seeded test cases expect only checks from the generatechecks prompt" do
    titles = Ai::IssueChecks.titles_in(Rails.root.join("db/seeds/fixtures/ai_prompt_generatechecks.md").read)

    assert_difference -> { Ai::PromptTestCase.count }, 24 do
      load Rails.root.join("db/seeds/ai_prompt_test_cases.rb")
    end
    assert_empty Ai::PromptTestCase.pluck(:expected_check_titles).flatten - titles

    assert_no_difference -> { Ai::PromptTestCase.count } do
      load Rails.root.join("db/seeds/ai_prompt_test_cases.rb")
    end
  end
end
