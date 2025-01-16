class Connector::SendNewIssueStatusToTriageFromBackofficeJob < ApplicationJob
  def perform(ticket_id, group_name, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    tenant = Connector::Tenant.find_by(name: group_name)
    issue = zammad_api_client.new(tenant).get_issue(ticket_id)
    ops_api_client.new(tenant).update_issue_status(issue.triage_identifier, issue.state)
  end
end
