class Connector::CreateNewBackofficeIssueFromTriageJob < ApplicationJob
  SKIPPED_TICKETS_OPS_STATES = %w[waiting rejected]

  def perform(
    tenant,
    issue_id,
    import: false,
    zammad_api_client: Connector::ZammadApiClient,
    ops_api_client: Connector::OpsApiClient,
    import_legacy_backoffice_activity_job: Connector::Legacy::ImportBackofficeActivityToBackofficeJob,
    import_legacy_private_backoffice_activity_job: Connector::Legacy::ImportPrivateBackofficeActivityToBackofficeJob,
    set_ticket_owner_job: Connector::SetBackofficeTicketOwnerJob
  )
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    issue_data = ops_client.get_issue(issue_id, include_customer_activities: tenant.receive_customer_activities?, exclude_responsible_subject_articles: import)
    raise "Failed to get issue data!" unless issue_data

    return if SKIPPED_TICKETS_OPS_STATES.include?(issue_data["ops_state"])

    if import
      zammad_client.check_import_mode! if import
      zammad_group = zammad_api_client::IMPORT_GROUP
      backoffice_state = ISSUE_OPS_STATE_TO_BACKOFFICE_STATE.fetch(issue_data["ops_state"])
    else
      backoffice_state = zammad_api_client::DEFAULT_STATE
      zammad_group = zammad_api_client::DEFAULT_GROUP
    end

    zammad_client.create_issue!(issue_data, state: backoffice_state, group: zammad_group)

    if import
      import_legacy_backoffice_activity_job.perform_later(tenant, issue_id)
      import_legacy_private_backoffice_activity_job.perform_later(tenant, issue.legacy_id)
      set_ticket_owner_job.perform_later(tenant, issue_id)
    end
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
