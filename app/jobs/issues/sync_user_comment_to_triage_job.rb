class Issues::SyncUserCommentToTriageJob < ApplicationJob
  queue_as :default

  def perform(user_comment)
    # TODO make there are no other editable user_comments
    if user_comment.within_editing_window?
      self.class.set(wait_until: user_comment.editing_window_end).perform_later(user_comment)
      return
    end

    ::SyncIssueActivitiesToTriageJob.perform_later(user_comment.issue)
  end
end
