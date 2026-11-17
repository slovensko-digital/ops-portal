class Gemini
  class Error < StandardError; end

  DEFAULT_MODEL = "gemini-2.5-flash"

  def self.generate(messages:, system_prompt:, response_schema: nil)
    conn = Faraday.new(
      url: "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent",
      params: { key: ENV["GEMINI_API_KEY"] },
      headers: {
        "content-type": "application/json"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
      f.options.timeout = 30
    end

    res = conn.post do |req|
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

  def self.model
    ENV["GEMINI_MODEL"].presence || DEFAULT_MODEL
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
