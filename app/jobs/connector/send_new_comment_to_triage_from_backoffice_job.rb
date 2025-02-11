class Connector::SendNewCommentToTriageFromBackofficeJob < ApplicationJob
  def perform(ticket_id, article_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    tenant = Connector::Tenant.find_by!(name: group_name)
    comment = zammad_api_client.new(tenant).get_comment(ticket_id, article_id)
    issue = Connector::Issue.find_by!(backoffice_external_id: ticket_id)
    comment_triage_external_id = ops_api_client.new(tenant).create_comment!(issue.triage_external_id, comment)

    Connector::Comment.create!(triage_external_id: comment_triage_external_id, backoffice_external_id: article_id)
  end
end
