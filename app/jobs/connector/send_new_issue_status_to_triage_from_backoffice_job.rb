class Connector::SendNewIssueStatusToTriageFromBackofficeJob < ApplicationJob
  def perform(tenant, ticket_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    issue_state = zammad_api_client.new(tenant).get_issue_state(ticket_id)
    ops_api_client.new(tenant).update_issue_status(tenant.issues.find_by(backoffice_external_id: ticket_id), issue_state)
  end
end
