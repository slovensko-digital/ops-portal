class Connector::CreateNewBackofficeCommentFromTriageJob < ApplicationJob
  def perform(tenant, issue_id, comment_id, zammad_api_client: Connector::ZammadApiClient, ops_api_client: Connector::OpsApiClient)
    ops_client = ops_api_client.new(tenant)
    zammad_client = zammad_api_client.new(tenant)

    comment = ops_client.get_comment(issue_id, comment_id)
    raise "Comment not found" unless comment
    zammad_client.create_comment!(issue_id, comment)
  end
end
