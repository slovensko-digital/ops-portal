class Issues::Draft::GenerateChecksJob < ApplicationJob
  queue_as :default

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
      messages: [ prompt ]
    )
  end
end
