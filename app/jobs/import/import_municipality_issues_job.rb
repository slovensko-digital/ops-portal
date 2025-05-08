module Import
  class ImportMunicipalityIssuesJob < ApplicationJob
    def perform(
      municipality:,
      municipality_district: nil,
      import_since: Date.parse("2020-01-01").beginning_of_day,
      import_issue_job: ImportIssueJob
    )
      conditions = {
        mesto: municipality.legacy_id,
        is_manual: 0 # !! DO NOT ever delete this condition !!
      }
      conditions.merge!(mestska_cast: municipality_district.legacy_id) if municipality_district

      Legacy::Alert.where(**conditions).where("posted_time >= ?", import_since.to_i).find_in_batches do |group|
        group.each do |legacy_record|
          import_issue_job.perform_later(legacy_record)
        end
      end
    end
  end
end
