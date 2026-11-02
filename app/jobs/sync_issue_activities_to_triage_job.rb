class SyncIssueActivitiesToTriageJob < ApplicationJob
  def perform(
    issue,
    triage_group:,
    import: false,
    sync_activity_object_job: SyncIssueActivityObjectToTriageJob
  )
    issue.activities.includes(:activity_object).find_each do |activity|
      next if activity.activity_object.triage_external_id.present?

      # perform, not perform_now: its retry would swallow the error and sync the next activity out of order.
      # This job retries instead and skips the activities already synced.
      sync_activity_object_job.new.perform(issue: issue, activity_object: activity.activity_object, triage_group: triage_group, import: import)
    end
  end
end
