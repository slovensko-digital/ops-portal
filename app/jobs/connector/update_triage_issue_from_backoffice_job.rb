class Connector::UpdateTriageIssueFromBackofficeJob < ApplicationJob
  def perform(tenant, ticket_id, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant), ops_api_client: Connector::OpsApiClient)
    issue_data = zammad_api_client.get_issue(ticket_id)
    ops_api_client.new(tenant).update_issue(tenant.issues.find_by(backoffice_external_id: ticket_id).triage_external_id, issue_data)
  end
end
