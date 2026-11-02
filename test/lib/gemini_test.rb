require "test_helper"

class GeminiTest < ActiveSupport::TestCase
  setup do
    @gemini_url = /generativelanguage\.googleapis\.com\/v1beta\/models\/gemini.*:generateContent/
  end

  teardown do
    WebMock.reset!
  end

  test "raises on a non-200 response instead of returning an empty result" do
    stub_request(:post, @gemini_url).to_return(status: 500, body: "Internal Server Error")

    assert_raises(Gemini::Error) do
      Gemini.generate(messages: [ "data" ], system_prompt: "prompt")
    end
  end

  test "raises when the response contains no candidates" do
    stub_request(:post, @gemini_url).to_return(
      body: "{}",
      headers: { "Content-Type" => "application/json" }
    )

    assert_raises(Gemini::Error) do
      Gemini.generate(messages: [ "data" ], system_prompt: "prompt")
    end
  end

  test "raises when the model returns invalid JSON" do
    stub_request(:post, @gemini_url).to_return(
      body: file_fixture("webmock/gemini/invalid-json.json").read,
      headers: { "Content-Type" => "application/json" }
    )

    assert_raises(Gemini::Error) do
      Gemini.generate(messages: [ "data" ], system_prompt: "prompt")
    end
  end

  test "parses and returns the model output" do
    stub_request(:post, @gemini_url).to_return(
      body: file_fixture("webmock/gemini/checks-empty.json").read,
      headers: { "Content-Type" => "application/json" }
    )

    assert_equal [], Gemini.generate(messages: [ "data" ], system_prompt: "prompt")
  end
end
