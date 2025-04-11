class Issues::Draft::GenerateChecksJob < ApplicationJob
  queue_as :default

  def perform(draft)
    draft.checks = llm_generate_checks(draft)
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
             #{[ draft.address_city, draft.address_city_district, draft.address_road ].compact.join(', ')}
    LLM

    Gemini.generate(
      system_prompt: Ai::Prompt.get("generatechecks"),
      messages: [ prompt ]
    )
  end
end
