class Connector::UpdateBackofficeIssueStatusFromTriageJob < ApplicationJob
  def perform(subject_id, issue_id, zammad_client: Connector::ApiEnvironment.zammad_client, ops_api: Connector::ApiEnvironment.ops_api)
  end
end
