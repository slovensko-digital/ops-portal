class Connector::CreateNewBackofficeIssueFromTriageJob < ApplicationJob
  def perform(
    tenant,
    issue_id,
    import: false,
    zammad_api_client: Connector::ZammadApiClient,
    ops_api_client: Connector::OpsApiClient,
    import_responsible_subject_activity_job: ImportResponsibleSubjectActivityToBackofficeJob,
    set_ticket_owner_job: SetBackofficeTicketOwnerJob
  )
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    issue_data = ops_client.get_issue(issue_id, include_customer_activities: tenant.receive_customer_activities?, exclude_responsible_subject_articles: import)

    if import
      zammad_client.check_import_mode! if import
      zammad_group = zammad_api_client::IMPORT_GROUP
      backoffice_state = ISSUE_STATE_TO_PROCESS_TYPE.fetch(issue_data["ops_state"])
    else
      backoffice_state = zammad_api_client::DEFAULT_STATE
      zammad_group = zammad_api_client::DEFAULT_GROUP
    end

    zammad_client.create_issue!(issue_data, state: backoffice_state, group: zammad_group)

    if import
      import_responsible_subject_activity_job.perform_later(tenant, issue_id)
      set_ticket_owner_job.perform_later(tenant. issue_id)
    end
  end

  ISSUE_STATE_TO_PROCESS_TYPE = {
    "sent_to_responsible" => "new",
    "in_progress" => "open",
    "referred" => "open",
    "marked_as_resolved" => "closed",
    "resolved" => "closed",
    "closed" => "closed",
    "unresolved" => "closed"
  }
end
