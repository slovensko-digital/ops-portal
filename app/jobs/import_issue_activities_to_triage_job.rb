class ImportIssueActivitiesToTriageJob < ApplicationJob
  def perform(issue, api: TriageZammadEnvironment.api, client: TriageZammadEnvironment.client)
    api.check_import_mode!

    issue.activities.includes(:activity_object).find_each do |activity|
      next if activity.activity_object.triage_external_id.present?

      activity.activity_object.author&.update!(zammad_identifier: client.create_customer!(activity.activity_object.author)) unless activity.activity_object.author&.zammad_identifier

      article_id = client.create_article!(issue.triage_external_id, activity.activity_object)

      raise unless article_id

      activity.activity_object.update!(
        triage_external_id: article_id
      )
    end
  end
end
