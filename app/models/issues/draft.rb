class Issues::Draft < ApplicationRecord
  has_many_attached :photos

  def calculate_suggestions
    llm_get_suggestions
  end

  def geo
    [ latitude, longitude ] if latitude.present? && longitude.present?
  end

  def load_geo_from_exif(photo)
    begin
      d = Exif::Data.new(photo.blob.download)
    rescue Exif::NotReadable
      return
    end

    gps = d[:gps]
    if gps
      self.latitude = gps_to_float(gps[:gps_latitude])
      self.longitude = gps_to_float(gps[:gps_longitude])
    end
  end

  private

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end

  SYSTEM_PROMPT = <<-LLM
    Your task is to analyze a photo that was uploaded by a citizen reporting a problem in municipality. 
    
    You should carefully look at the photo and suggest a title and description of distinct problems that will be approved by a human later. Title should be descriptive and less than 100 characters, description must be concise a clear so a civil servant will understand it. 
    
    Never suggest more than 3 problems.
    Suggestions should not have duplicates.
    Do not suggest vague or ambiguous issues.
    If you are unsure about the problem in the photo say so.
    
    Return response in Slovak language in JSON array, where each suggestion is a map with keys `title`, `description` and `confidence`. `confidence` can be `high` or `low`. Resulting array should be sorted from highest to lowest confidence. Return empty map if you are very unsure about suggestions.
  LLM

  def llm_get_suggestions
    conn = Faraday.new(
      url: "https://api.anthropic.com",
      headers: {
        "x-api-key": ENV["ANTHROPIC_API_KEY"],
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
      }
    ) do |f|
      f.response :json
    end

    res = conn.post("v1/messages") do |req|
      req.body = {
        messages: [
          {
            role: :user,
            content: photos.map do |photo|
              {
                type: :image,
                source: {
                  type: :base64,
                  media_type: photo.blob.content_type,
                  data: Base64.strict_encode64(photo.blob.download)
                }
              }
            end
          }
        ],
        system: SYSTEM_PROMPT,
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024
      }.to_json
    end

    JSON.parse(res.body["content"].first["text"])
  end
end
