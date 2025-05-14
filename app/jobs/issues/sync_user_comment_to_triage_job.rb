class Issues::SyncUserCommentToTriageJob < ApplicationJob
  queue_as :default

  def perform(user_comment)
    if user_comment.within_editing_window?
      self.class.set(wait_until: user_comment.editing_window_end).perform_later(user_comment)
      return
    end

    ::SyncIssueActivityObjectToTriageJob.perform_later(issue: user_comment.issue, activity_object: user_comment)
  end
end
