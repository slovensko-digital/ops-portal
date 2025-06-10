module Import
  class ImportLegacyIssuesToTriageJob < ApplicationJob
    queue_with_priority 100

    def perform(municipality:, municipality_district: nil, import_issue_job: ::SyncIssueToTriageJob)
      conditions = {
        municipality: municipality
      }
      conditions.merge!(municipality_district: municipality_district) if municipality_district

      Issue
        .where.not(legacy_id: nil)
        .where(**conditions).find_in_batches do |group|
        group.each do |issue|
          import_issue_job.perform_later(issue, import: true)
        end
      end
    end
  end
end
