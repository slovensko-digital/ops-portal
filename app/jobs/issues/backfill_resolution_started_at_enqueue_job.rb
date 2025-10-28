class Issues::BackfillResolutionStartedAtEnqueueJob < ApplicationJob
  queue_as :default

  def perform(child_job_queue: :default)
    Issue.where.not(resolution_external_id: nil).where(resolution_started_at: nil).find_each do |issue|
      Issues::BackfillResolutionStartedAtJob.set(queue: child_job_queue).perform_later(issue)
    end
  end
end
