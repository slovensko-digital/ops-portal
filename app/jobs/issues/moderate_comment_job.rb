class Issues::ModerateCommentJob < ApplicationJob
  queue_as :default

  def perform(comment)
    return if comment.text.blank?

    evaluation = llm_evaluate_comment(comment)

    score = evaluation["overall_score"].to_f
    threshold = ENV.fetch("COMMENT_AUTO_HIDE_THRESHOLD", 0.9).to_f

    comment.ai_evaluation = evaluation
    comment.hidden = true if score >= threshold
    comment.save!
  end

  private

  def llm_evaluate_comment(comment)
    prompt = <<~LLM
      Podnet

      Title:
      #{comment.issue.title}

      Description:
      #{comment.issue.description}

      Comment to evaluate:
      #{comment.text}
    LLM

    Gemini.generate(
      system_prompt: Ai::Prompt.get("moderatecomments"),
      messages: [ prompt ],
      response_schema: {
        type: "OBJECT",
        properties: {
          irrelevant: { type: "NUMBER", description: "Confidence score 0.0-1.0 for off-topic or spam content" },
          vulgar: { type: "NUMBER", description: "Confidence score 0.0-1.0 for vulgarity, coarse language, and swearing" },
          insulting: { type: "NUMBER", description: "Confidence score 0.0-1.0 for personal insults or attacks on officials" },
          sarcastic: { type: "NUMBER", description: "Confidence score 0.0-1.0 for destructive sarcasm, irony, or mocking" },
          political: { type: "NUMBER", description: "Confidence score 0.0-1.0 for political attacks or election agitation" },
          overall_score: { type: "NUMBER", description: "Overall inappropriateness confidence score from 0.0 to 1.0" },
          reason: { type: "STRING", description: "Short explanation of the evaluation in Slovak language" }
        },
        required: %w[irrelevant vulgar insulting sarcastic political overall_score reason]
      }
    )
  end
end
