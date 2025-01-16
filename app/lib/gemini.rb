class Gemini
  def self.generate(messages:, system_prompt:)
    conn = Faraday.new(
      url: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent",
      params: { key: ENV["GEMINI_API_KEY"] },
      headers: {
        "content-type": "application/json"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
    end

    res = conn.post do |req|
      req.body = {
        contents: [
          {
            parts: messages.map { build_message(_1) }
          }
        ],
        system_instruction: { parts: [ { text: system_prompt } ] },
        generationConfig: { response_mime_type: "application/json" }
      }.to_json
    end

    return [] unless res.body["candidates"]
    JSON.parse(res.body["candidates"].first.dig("content", "parts").first["text"])
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
