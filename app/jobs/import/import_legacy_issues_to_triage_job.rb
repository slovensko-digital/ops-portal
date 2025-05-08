module Import
  class ImportLegacyIssuesToTriageJob < ApplicationJob
    queue_with_priority 100

    def perform(municipality:, municipality_district: nil, import_issue_job: ::SyncIssueToTriageJob)
      Issue
        .where.not(legacy_id: nil)
        .where(municipality: municipality)
        .where(municipality_district: municipality_district).find_in_batches do |group|
        group.each do |issue|
          import_issue_job.perform_later(issue, import: true)
        end
      end
    end
  end
end
