class Connector::SendNewCommentToTriageFromBackofficeJob < ApplicationJob
  def perform(tenant, ticket_id, article_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    return if tenant.comments.find_by(backoffice_external_id: article_id).present?

    comment = zammad_api_client.new(tenant).get_comment(ticket_id, article_id)
    issue = tenant.issues.find_by!(backoffice_external_id: ticket_id)
    comment_triage_external_id = ops_api_client.new(tenant).create_comment!(issue.triage_external_id, comment)

    tenant.comments.create!(triage_external_id: comment_triage_external_id, backoffice_external_id: article_id)
  end
end
