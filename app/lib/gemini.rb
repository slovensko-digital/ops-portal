class Gemini
  class Error < StandardError; end

  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  DEFAULT_MODEL = "gemini-2.5-flash"
  MODEL_FORMAT = /\A[a-z0-9][a-z0-9.\-]*\z/

  def self.generate(messages:, system_prompt:, response_schema: nil, model: DEFAULT_MODEL, timeout: 30)
    raise ArgumentError, "Invalid Gemini model #{model.inspect}" unless model.to_s.match?(MODEL_FORMAT)

    res = connection(timeout:).post("models/#{model}:generateContent") do |req|
      body = {
        contents: [
          {
            parts: messages.map { build_message(_1) }
          }
        ],
        system_instruction: { parts: [ { text: system_prompt } ] },
        generationConfig: { responseMimeType: "application/json" }
      }

      body[:generationConfig].merge!(responseSchema: response_schema) if response_schema

      req.body = body.to_json
    end

    if res.status != 200
      Rails.logger.error(res.body.to_s)
      Rollbar.error(res.body.to_s)
      raise Error, "Gemini API returned status #{res.status}"
    end

    text = res.body.dig("candidates", 0, "content", "parts", 0, "text") if res.body.is_a?(Hash)
    raise Error, "Gemini API returned no candidates" if text.blank?

    begin
      JSON.parse(text)
    rescue JSON::ParserError => e
      raise Error, "Gemini API returned invalid JSON: #{e.message}"
    end
  end

  # Names of the models that support generateContent, e.g. "gemini-2.5-flash".
  def self.models
    res = connection.get("models", pageSize: 1000)
    raise Error, "Gemini API returned status #{res.status}" if res.status != 200

    res.body.fetch("models", [])
      .select { _1["supportedGenerationMethods"].to_a.include?("generateContent") }
      .map { _1["name"].delete_prefix("models/") }
      .sort
  end

  def self.connection(timeout: 30)
    Faraday.new(
      url: "#{BASE_URL}/",
      params: { key: ENV["GEMINI_API_KEY"] },
      headers: {
        "content-type": "application/json"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
      f.options.timeout = timeout
    end
  end

  def self.build_message(thing)
    case thing
    when String
        { text: thing }
    when ActiveStorage::Attachment
        {
          inline_data: {
            mime_type: thing.blob.content_type,
            data: Base64.strict_encode64(thing.variant(:llm).processed.download)
          }
        }
    else
        raise "Unknown thing"
    end
  end
end
