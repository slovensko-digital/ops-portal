module Import
  class ImportLegacyIssuesFromTriageToBackofficeJob < ApplicationJob
    queue_with_priority 100

    def perform(responsible_subject, import_issue_from_triage_job: ::Connector::CreateNewBackofficeIssueFromTriageJob, import_manual_issues_job: ::Connector::Legacy::ImportManualBackofficeAlertsFromLegacyDbToBackofficeJob)
      client = ::Client.find_by(responsible_subject: responsible_subject)
      tenant = ::Connector::Tenant.find_by(ops_api_subject_identifier: client.id)

      Issue.where.not(legacy_id: nil).where(responsible_subject: responsible_subject).find_in_batches do |group|
        group.each do |issue|
          import_issue_from_triage_job.perform_later(tenant, issue.triage_external_id, import: true)
        end
      end

      import_manual_issues_job.perform_later(tenant)
    end
  end
end
