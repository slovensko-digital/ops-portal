class Issues::Draft::GenerateChecksJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(draft)
    draft.checks = llm_generate_checks(draft)
    draft.save!
  end

  private

  def llm_generate_checks(draft)
    data = {
      title: draft.title,
      description: draft.description,
      address: [ draft.address_city, draft.address_municipality, draft.address_street ].compact.join(", ")
    }.to_json

    checks = Gemini.generate(
      system_prompt: Ai::Prompt.get("generatechecks"),
      messages: [ data ],
      response_schema: {
        "type": "ARRAY",
        "items": {
          "type": "OBJECT",
          "properties": {
            "title": { "type": "STRING" },
            "info": { "type": "STRING" },
            "more_info": { "type": "STRING" },
            "action": { "type": "STRING" },
            "explanation": { "type": "STRING" }
          },
          required: [ "title", "info", "action" ]
        }
      }
    )

    sanitize_more_info_urls(checks)
  end

  def sanitize_more_info_urls(checks)
    return checks unless checks.is_a?(Array)

    checks.each do |check|
      next unless check.is_a?(Hash) && check.key?("more_info")

      check["more_info"] = nil unless SafeUrl.allowed?(check["more_info"])
    end

    checks
  end
end
