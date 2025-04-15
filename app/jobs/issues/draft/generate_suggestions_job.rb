class Issues::Draft::GenerateSuggestionsJob < ApplicationJob
  queue_as :default

  def perform(draft)
    draft.suggestions = generate_suggestions(draft)
    draft.save!
  end

  private

  def generate_suggestions(draft)
    Gemini.generate(
      messages: [ "" ] + draft.photos,
      system_prompt: Ai::Prompt.get("generatesuggestions")
    )
  end
end
