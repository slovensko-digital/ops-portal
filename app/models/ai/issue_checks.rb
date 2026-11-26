# Asks Gemini which checks from the generatechecks prompt a reported problem fails.
# Used by Issues::Draft::GenerateChecksJob and by the admin prompt playground, so the
# playground sends exactly the request the wizard does.
module Ai
  class IssueChecks
    PROMPT_NAME = "generatechecks"

    RESPONSE_SCHEMA = {
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
    }.freeze

    def self.generate(title:, description:, address:, system_prompt: Ai::Prompt.get(PROMPT_NAME), **gemini_options)
      data = { title:, description:, address: }.to_json

      checks = Gemini.generate(
        system_prompt:,
        messages: [ data ],
        response_schema: RESPONSE_SCHEMA,
        **gemini_options
      )

      sanitize_more_info_urls(checks)
    end

    # Check titles listed in the prompt's checks dictionary ("Title: Parkovanie").
    def self.titles_in(prompt)
      prompt.to_s.scan(/^Title:[ \t]*(.+?)[ \t]*$/).flatten.uniq
    end

    def self.sanitize_more_info_urls(checks)
      return checks unless checks.is_a?(Array)

      checks.each do |check|
        next unless check.is_a?(Hash) && check.key?("more_info")

        check["more_info"] = nil unless SafeUrl.allowed?(check["more_info"])
      end

      checks
    end
  end
end
