class Issues::SyncEditableActivityToTriageJob < ApplicationJob
  queue_as :default

  def perform(activity_object, sync_job:)
    if activity_object.within_editing_window?
      self.class.set(wait_until: activity_object.editing_window_end).perform_later(activity_object, sync_job: sync_job)
      return
    end

    # moderate before syncing so a hidden comment reaches triage as internal;
    # a failed moderation is discarded and does not block the sync
    Issues::ModerateCommentJob.perform_now(activity_object) if activity_object.is_a?(Issues::UserComment)

    sync_job.perform_later(issue: activity_object.issue, activity_object: activity_object)
  end
end
