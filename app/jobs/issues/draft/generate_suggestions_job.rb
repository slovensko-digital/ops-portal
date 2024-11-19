class Issues::Draft::GenerateSuggestionsJob < ApplicationJob
  queue_as :default

  def perform(draft)
    draft.suggestions = generate_suggestions(draft)
    draft.save!
  end

  private

  SYSTEM_PROMPT = <<-LLM
    Your task is to analyze a photo that was uploaded by a citizen reporting a problem in municipality.

    You should carefully look at the photo and suggest a title and description of distinct problems that will be approved by a human later.#{' '}
    Title should be descriptive and less than 100 characters, description must be concise a clear so a civil servant will understand it.

    Never suggest more than 3 problems, try to suggest 2 problems.
    Suggestions should not have duplicates.
    Do not suggest vague or ambiguous issues.
    If you are unsure about the problem in the photo say so.

    Return response in Slovak language in JSON array, where each suggestion is a map with keys `title`, `description`, `category`, `subcategory` and `subtype`.
    Resulting array should be sorted from highest to lowest confidence.
    Return empty array `[]` and nothing else if there are no problems on the photo.

    Categories, subcategories and types with examples.
    | Category                  | Subcategory      | Subtype             | Valid examples |
    | ------------------------- | ---------------- | --------------------| -------- |
    | Cesty, prícestný mobiliár | Druh komunikácie | cesta               | výtlk / rozbitá cesta (väčší úsek) / znečistená / neodhrnutá / neposypaná / rozkopaná / poškodená dlažba |
    | Cesty, prícestný mobiliár | Druh komunikácie | chodník             | výtlk / znečistený / neodhrnutý / neposypaný / rozkopaný / chýbajúci / poškodená dlažba / bariéra na chodníku |
    | Cesty, prícestný mobiliár | Druh komunikácie | cyklotrasa          | poškodená / chýbajúca / neoznačená / znečistená / neodhrnutá / neposypaná / výtlk |
    | Cesty, prícestný mobiliár | Druh komunikácie | schody              | poškodená / znečistená / neodhrnutá / neposypaná / bariérové |
    | Cesty, prícestný mobiliár | Mobiliár         | kôš 	               | poškodený / preplnený / chýbajúci / nevhodne umiestnený / chýbajúce sáčky
    | Cesty, prícestný mobiliár | Mobiliár         | kvetináč            | poškodený / posunutý / zanedbaný / chýbajúci
    | Cesty, prícestný mobiliár | Mobiliár         | cyklostojan         | chýbajúci / poškodený / zle umiestnený
    | Cesty, prícestný mobiliár | Mobiliár         | rozvodná skriňa     | poškodená rozvodná skriňa / nebezpečný kábel
    | Cesty, prícestný mobiliár | Mobiliár         | zábradlie/oplotenie | chýbajúce / poškodené / zhrdzavené
    | Cesty, prícestný mobiliár | Značenie         | Vodorovné dopravné značenie | chýbajúce / neaktuálne / zle viditeľné
    | Cesty, prícestný mobiliár | Značenie         | Zvislé dopravné značenie |	poškodené / neaktuálne / chýbajúce / vyblednuté / zle otočené
    | Cesty, prícestný mobiliár | Značenie         | Semafor             | nefunkčný / zle nastavený / chýbajúci
    | Cesty, prícestný mobiliár | Značenie         | Spomaľovač	         | chýbajúci / poškodený
    | Cesty, prícestný mobiliár | Značenie         | Dopravné zrkadlo	   | chýbajúce / poškodené / zle natočené
    | Cesty, prícestný mobiliár | Značenie         | Priechod pre chodcov |	chýbajúci / zle viditeľný / bariérový
    | Cesty, prícestný mobiliár | Značenie         | Protiparkovacia zábrana/stĺpik/biskupský klobúk |	Chýbajúca / poškodená  / posunutá
    | Doprava                   | Parkovanie       | Zle zaparkované vozidlo | nelegálne zaparkované vozidlo
    | Stavby mesta              | Budova           |                      | poškodená / grafity / nevyužívaná |
    | Stavby mesta              | Most             |                      | poškodený / grafity |
    | Stavby mesta              | Stánok           |                      | poškodený / grafity / nevyužívaná |
    | Stavby mesta              | Terasa           |                      | poškodená / grafity / nevyužívaná |
    | Iné                       |                  |                      | všetko ostatné |
  LLM

  def generate_suggestions(draft)
    conn = Faraday.new(
      url: "https://api.anthropic.com",
      headers: {
        "x-api-key": ENV["ANTHROPIC_API_KEY"],
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
    end

    res = conn.post("v1/messages") do |req|
      req.body = {
        messages: [
          {
            role: :user,
            content: draft.photos.map do |photo|
              {
                type: :image,
                source: {
                  type: :base64,
                  media_type: photo.blob.content_type,
                  data: Base64.strict_encode64(photo.variant(resize_to_limit: [ 800, 600 ]).processed.download)
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
