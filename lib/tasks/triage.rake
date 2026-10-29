namespace :triage do
  desc "Backfill issue state-change and responsible-subject timelines from triage ticket history"
  task backfill_history: :environment do
    scope = Issue.where.not(triage_external_id: nil).or(Issue.where.not(resolution_external_id: nil))
    Rails.logger.info "Enqueuing history backfill for #{scope.count} issues..."

    scope.find_each do |issue|
      Triage::BackfillIssueHistoryJob.perform_later(issue)
    end

    Rails.logger.info "Done enqueuing."
  end
end
