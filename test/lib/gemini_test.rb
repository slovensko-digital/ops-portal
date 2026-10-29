require "test_helper"

class GeminiTest < ActiveSupport::TestCase
  setup do
    @gemini_url = /generativelanguage\.googleapis\.com\/v1beta\/models\/gemini.*:generateContent/
  end

  teardown do
    ENV.delete("GEMINI_MODEL")
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

  test "calls the default model unless GEMINI_MODEL is set" do
    stub_model("gemini-2.5-flash")

    assert_equal [ 1 ], Gemini.generate(messages: [ "data" ], system_prompt: "prompt")
  end

  test "calls the model from GEMINI_MODEL" do
    ENV["GEMINI_MODEL"] = "gemini-3.8-flash"
    stub_model("gemini-3.8-flash")

    assert_equal [ 1 ], Gemini.generate(messages: [ "data" ], system_prompt: "prompt")
  end

  private

  def stub_model(model)
    stub_request(:post, %r{/v1beta/models/#{model}:generateContent}).to_return(
      headers: { "Content-Type" => "application/json" },
      body: { candidates: [ { content: { parts: [ { text: "[1]" } ] } } ] }.to_json
    )
  end
end
