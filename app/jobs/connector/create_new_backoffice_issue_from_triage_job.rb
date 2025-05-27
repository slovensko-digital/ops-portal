class Connector::CreateNewBackofficeIssueFromTriageJob < ApplicationJob
  SKIPPED_TICKETS_OPS_STATES = %w[waiting rejected]

  def perform(
    tenant,
    issue_id,
    import: false,
    zammad_client: Connector::BackofficeZammadEnvironment.client(tenant),
    ops_api_client: Connector::OpsApiClient,
    import_legacy_backoffice_activity_job: Connector::Legacy::ImportBackofficeActivityFromTriageToBackofficeJob,
    import_legacy_internal_backoffice_activity_job: Connector::Legacy::ImportInternalBackofficeActivityFromLegacyDbToBackofficeJob,
    set_ticket_owner_job: Connector::Legacy::SetBackofficeTicketOwnerJob
  )
    ops_client = ops_api_client.new(tenant)

    issue_data = ops_client.get_issue(issue_id, include_customer_activities: tenant.receive_customer_activities?, exclude_responsible_subject_articles: import)
    raise "Failed to get issue data!" unless issue_data

    return if SKIPPED_TICKETS_OPS_STATES.include?(issue_data["ops_state"])

    return zammad_client.create_issue!(issue_data) unless import

    zammad_client.check_import_mode!
    zammad_group = zammad_client.class.const_get("IMPORT_GROUP")
    backoffice_state = ISSUE_OPS_STATE_TO_BACKOFFICE_STATE.fetch(issue_data["ops_state"])

    zammad_client.create_issue!(issue_data, state: backoffice_state, group: zammad_group)

    import_legacy_backoffice_activity_job.perform_later(tenant, issue_id)
    import_legacy_internal_backoffice_activity_job.perform_later(tenant, issue_id)
    set_ticket_owner_job.perform_later(tenant, issue_id)
  end

  ISSUE_OPS_STATE_TO_BACKOFFICE_STATE = {
    "sent_to_responsible" => "new",
    "in_progress" => "open",
    "referred" => "open",
    "marked_as_resolved" => "closed",
    "resolved" => "closed",
    "closed" => "closed",
    "unresolved" => "closed"
  }
end
