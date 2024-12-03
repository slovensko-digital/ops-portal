class OvmConnector::UpdateIssueStatusJob < ApplicationJob
  def perform(subject_id, issue_id, zammad_client: OvmConnector::ApiEnvironment.zammad_client, ops_api: OvmConnector::ApiEnvironment.ops_api)
  end
end
