class OvmConnector::CreateNewCommentJob < ApplicationJob
  def perform(subject_id, issue_id, comment_id, zammad_client: OvmConnector::ApiEnvironment.zammad_client, ops_api: OvmConnector::ApiEnvironment.ops_api)
  end
end
