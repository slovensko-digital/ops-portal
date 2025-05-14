class SyncIssueActivitiesToTriageJob < ApplicationJob
  def perform(
    issue,
    triage_group:,
    import: false,
    sync_activity_object_job: SyncIssueActivityObjectToTriageJob
  )
    issue.activities.includes(:activity_object).find_each do |activity|
      next if activity.activity_object.triage_external_id.present?

      sync_activity_object_job.perform_now(issue: issue, activity_object: activity.activity_object, triage_group: triage_group, import: import)
    end
  end
end
