require "test_helper"

class GeminiTest < ActiveSupport::TestCase
  teardown do
    ENV.delete("GEMINI_MODEL")
    WebMock.reset!
  end

  test "calls the default model unless GEMINI_MODEL is set" do
    stub_gemini("gemini-2.5-flash")

    assert_equal [ 1 ], generate
  end

  test "calls the model from GEMINI_MODEL" do
    ENV["GEMINI_MODEL"] = "gemini-3.8-flash"
    stub_gemini("gemini-3.8-flash")

    assert_equal [ 1 ], generate
  end

  test "returns an empty result on an error response" do
    stub_gemini_error

    assert_equal [], generate
  end

  test "raises on an error response when asked to" do
    stub_gemini_error

    error = assert_raises(Gemini::Error) { generate(raise_on_error: true) }
    assert_match "NOT_FOUND", error.message
  end

  private

  def generate(**options)
    Gemini.generate(messages: [ "text" ], system_prompt: "prompt", **options)
  end

  def stub_gemini(model)
    stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=").to_return(
      headers: { "Content-Type" => "application/json" },
      body: { candidates: [ { content: { parts: [ { text: "[1]" } ] } } ] }.to_json
    )
  end

  def stub_gemini_error
    stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=").to_return(
      status: 404,
      headers: { "Content-Type" => "application/json" },
      body: { error: { code: 404, message: "Model not available", status: "NOT_FOUND" } }.to_json
    )
  end
end
