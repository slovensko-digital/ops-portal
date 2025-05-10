class Issues::Draft::GenerateChecksJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(draft)
    draft.checks = llm_generate_checks(draft)
    draft.save!
  end

  private

  def llm_generate_checks(draft)
    prompt = <<-LLM
             Podnet

             Title:
             #{draft.title}

             Description:
             #{draft.description}

             Address:
             #{[ draft.address_city, draft.address_municipality, draft.address_street ].compact.join(', ')}
    LLM

    Gemini.generate(
      system_prompt: Ai::Prompt.get("generatechecks"),
      messages: [ prompt ],
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
  end
end
