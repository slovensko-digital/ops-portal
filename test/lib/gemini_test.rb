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

  test "calls the production model by default" do
    stub_request(:post, %r{/models/gemini-2\.5-flash:generateContent}).to_return(
      body: file_fixture("webmock/gemini/checks-empty.json").read,
      headers: { "Content-Type" => "application/json" }
    )

    Gemini.generate(messages: [ "data" ], system_prompt: "prompt")

    assert_requested :post, %r{/models/gemini-2\.5-flash:generateContent}
  end

  test "calls the given model" do
    stub_request(:post, %r{/models/gemini-2\.5-pro:generateContent}).to_return(
      body: file_fixture("webmock/gemini/checks-empty.json").read,
      headers: { "Content-Type" => "application/json" }
    )

    Gemini.generate(messages: [ "data" ], system_prompt: "prompt", model: "gemini-2.5-pro")

    assert_requested :post, %r{/models/gemini-2\.5-pro:generateContent}
  end

  test "rejects a model name that is not a plain model id" do
    assert_raises(ArgumentError) do
      Gemini.generate(messages: [ "data" ], system_prompt: "prompt", model: "../files")
    end
  end

  test "lists the models that can generate content" do
    stub_request(:get, %r{generativelanguage\.googleapis\.com/v1beta/models\?}).to_return(
      body: file_fixture("webmock/gemini/models.json").read,
      headers: { "Content-Type" => "application/json" }
    )

    assert_equal %w[gemini-2.5-flash gemini-2.5-pro], Gemini.models
  end

  test "returns the billed tokens, counting thinking as output" do
    stub_request(:post, @gemini_url).to_return(
      body: file_fixture("webmock/gemini/checks-parking.json").read,
      headers: { "Content-Type" => "application/json" }
    )

    response = Gemini.request(messages: [ "data" ], system_prompt: "prompt")

    assert_equal Gemini::Usage.new(input_tokens: 2000, output_tokens: 200), response.usage
    assert_in_delta 0.0011, response.usage.cost(Gemini::Price.new(input: 0.30, output: 2.50))
    assert_nil response.usage.cost(nil)
  end

  test "prices a model for the period the day falls in" do
    assert_equal Gemini::Price.new(input: 0.30, output: 2.50), Gemini.price("gemini-2.5-flash")
    assert_equal Gemini::Price.new(input: 2.00, output: 10.00), Gemini.price("gemini-4-carbon", on: Date.new(2026, 11, 30))
    assert_equal Gemini::Price.new(input: 4.00, output: 20.00), Gemini.price("gemini-4-carbon", on: Date.new(2026, 12, 1))
    assert_nil Gemini.price("gemini-unknown")
  end
end
