require "test_helper"
require "test_helpers/issues/drafts_helper"

class Issues::Draft::GenerateSuggestionsJobTest < ActiveJob::TestCase
  include Issues::DraftsHelper

  setup do
    @draft = Issues::Draft.create!(author: users(:one))

    @gemini_url = /generativelanguage\.googleapis\.com\/v1beta\/models\/gemini.*:generateContent/
  end

  teardown do
    WebMock.reset!
  end

  test "stores suggestions returned by Gemini" do
    stub_json_request(:post, @gemini_url, response: "webmock/gemini/suggestions-graffiti.json")

    Issues::Draft::GenerateSuggestionsJob.perform_now(@draft)

    @draft.reload
    assert @draft.suggestions.any?
    assert_equal "Poškodená rozvodná skriňa", @draft.suggestions.first["title"]
  end

  test "stores empty suggestions instead of raising when the Gemini API fails" do
    stub_request(:post, @gemini_url).to_return(status: 500, body: "Internal Server Error")

    assert_nothing_raised do
      Issues::Draft::GenerateSuggestionsJob.perform_now(@draft)
    end

    assert_equal [], @draft.reload.suggestions
  end
end
