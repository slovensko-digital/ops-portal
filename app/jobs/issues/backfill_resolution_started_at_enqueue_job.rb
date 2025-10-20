class Issues::BackfillResolutionStartedAtEnqueueJob < ApplicationJob
  queue_as :default

  DEFAULT_BATCH_SIZE = 500

  def perform(batch_size: DEFAULT_BATCH_SIZE)
    scope = Issue.where.not(resolution_external_id: nil).where(resolution_started_at: nil).select(:id)
    return unless scope.exists?

    scope.in_batches(of: batch_size) do |relation|
      Issues::BackfillResolutionStartedAtBatchJob.perform_later(issue_ids: relation.ids)
    end
  end
end
