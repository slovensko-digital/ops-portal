class Issues::SyncActivityToTriageJob < ApplicationJob
  queue_as :default

  def perform(activity_object, sync_job:)
    sync_job.perform_later(issue: activity_object.issue, activity_object: activity_object)
  end
end
