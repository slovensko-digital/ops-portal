class Issues::Draft < ApplicationRecord
  has_many_attached :photos

  validates_presence_of :title, :description, :author, on: :details_step

  def calculate_suggestions
    self.suggestions = llm_get_suggestions
  end

  def geo
    [latitude, longitude] if latitude.present? && longitude.present?
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

  def load_suggestion
    self.title, self.description = suggestions[picked_suggestion_index]&.values_at("title", "description")
    self.title = self.description = nil if picked_suggestion_index == -1
  end

  def update_with_context(attributes, context)
    # TODO move to AR monkey-patch
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context)
    end
  end

  private

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end

  SYSTEM_PROMPT = <<-LLM
    Your task is to analyze a photo that was uploaded by a citizen reporting a problem in municipality.#{' '}

    You should carefully look at the photo and suggest a title and description of distinct problems that will be approved by a human later. Title should be descriptive and less than 100 characters, description must be concise a clear so a civil servant will understand it.#{' '}

    Never suggest more than 3 problems.
    Suggestions should not have duplicates.
    Do not suggest vague or ambiguous issues.
    If you are unsure about the problem in the photo say so.

    Return response in Slovak language in JSON array, where each suggestion is a map with keys `title`, `description`.
    Resulting array should be sorted from highest to lowest confidence.
    Return empty array `[]` and nothing else if there are no problems on the photo.
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
                  data: Base64.strict_encode64(photo.variant(resize_to_limit: [800, 600]).processed.download)
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
