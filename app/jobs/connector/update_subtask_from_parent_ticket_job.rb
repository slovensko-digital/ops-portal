class Connector::UpdateSubtaskFromParentTicketJob < ApplicationJob
  def perform(tenant, ticket_id: nil, issue_id: nil, zammad_api_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_api_client.update_subtasks(ticket_id) if ticket_id
    zammad_api_client.update_subtasks(tenant.issues.find_by(triage_external_id: issue_id).backoffice_external_id) if issue_id
  end
end
