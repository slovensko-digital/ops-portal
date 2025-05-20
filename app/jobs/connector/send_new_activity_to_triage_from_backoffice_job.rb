class Connector::SendNewActivityToTriageFromBackofficeJob < ApplicationJob
  def perform(tenant, ticket_id, article_id, zammad_environment: Connector::BackofficeZammadEnvironment, ops_api_client: Connector::OpsApiClient)
    return if tenant.activities.find_by(backoffice_external_id: article_id)&.triage_external_id

    activity = zammad_environment.client(tenant).get_activity(ticket_id, article_id)
    issue = tenant.issues.find_by!(backoffice_external_id: ticket_id)
    activity_triage_external_id = ops_api_client.new(tenant).create_activity!(issue.triage_external_id, activity)

    tenant.activities.create!(triage_external_id: activity_triage_external_id, backoffice_external_id: article_id)
  end
end
