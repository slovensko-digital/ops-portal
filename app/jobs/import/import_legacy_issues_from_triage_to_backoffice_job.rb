module Import
  class ImportLegacyIssuesFromTriageToBackofficeJob < ApplicationJob
    queue_with_priority 100

    SKIPPED_TICKETS_OPS_STATES = %w[waiting rejected]

    def perform(responsible_subject, import_issue_from_triage_job: ::Connector::CreateNewBackofficeIssueFromTriageJob, import_manual_issues_job: ::Connector::Legacy::ImportManualBackofficeAlertsFromLegacyDbToBackofficeJob)
      client = ::Client.find_by(responsible_subject: responsible_subject)
      tenant = ::Connector::Tenant.find_by(ops_api_subject_identifier: client.id)

      zammad_api_client = ::Connector::BackofficeZammadEnvironment.client(tenant)
      zammad_api_client.check_import_mode!(force: true)

      Issue.where.not(legacy_id: nil).where.not(resolution_external_id: nil).where(responsible_subject: responsible_subject).find_each do |issue|
        next if SKIPPED_TICKETS_OPS_STATES.include?(issue.state&.key)

        import_issue_from_triage_job.set(queue: queue_name).perform_later(tenant, issue.resolution_external_id, import: true)
      end

      import_manual_issues_job.set(queue: queue_name).perform_later(tenant)
    end
  end
end
