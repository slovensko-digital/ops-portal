class SyncMunicipalityIssuesToTriageJob < ApplicationJob
  def perform(
    municipality:,
    municipality_district:,
    client: TriageZammadEnvironment.client,
    import: false,
    sync_issue_to_triage_job: SyncIssueToTriageJob
  )
    client.check_import_mode!(force: true) if import

    Issue.where(municipality: municipality).where(municipality_district: municipality_district).find_each do |issue|
      sync_issue_to_triage_job.perform_later(issue, import: import)
    end
  end
end
