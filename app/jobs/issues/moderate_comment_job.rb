class Issues::ModerateCommentJob < ApplicationJob
  queue_as :default

  # moderation is best effort, a failure leaves the comment visible
  discard_on StandardError do |_job, error|
    Rollbar.error(error)
  end

  def perform(comment)
    return if comment.text.blank? || comment.ai_evaluation.present?

    evaluation = llm_evaluate_comment(comment)
    return unless evaluation.is_a?(Hash)

    score = evaluation["overall_score"].to_f
    threshold = ENV.fetch("COMMENT_AUTO_HIDE_THRESHOLD", 0.9).to_f

    comment.ai_evaluation = evaluation

    # hidden is shared with triage: the comment syncs as an internal
    # article and an agent can unhide it by making the article public
    comment.hidden = true if score >= threshold

    comment.save!
  end

  private

  def llm_evaluate_comment(comment)
    data = {
      issue_title: comment.issue.title,
      issue_description: comment.issue.description,
      comment_text: comment.text
    }.to_json

    Gemini.generate(
      system_prompt: Ai::Prompt.get("moderatecomments"),
      messages: [ data ],
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
