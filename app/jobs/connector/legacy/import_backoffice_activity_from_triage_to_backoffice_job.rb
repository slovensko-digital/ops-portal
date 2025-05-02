class Connector::Legacy::ImportBackofficeActivityFromTriageToBackofficeJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_api_client: Connector::ZammadApiClient)
    zammad_client = zammad_api_client.new(tenant)
    zammad_client.check_import_mode!

    issue = Issue.find_by(triage_external_id: triage_issue_id)

    issue.activities.includes(:activity_object).find_each do |activity|
      next unless backoffice_activity?(activity.activity_object)

      raise "Activity not synced to triage! #{activity.id}" unless activity.activity_object.triage_external_id.present?

      zammad_client.find_or_create_article_from_activity_object!(issue, activity.activity_object, internal: activity.activity_object.internal?, sender: "Agent")
    end
  end

  private

  def backoffice_activity?(activity_object)
    activity_object.is_a?(::Issues::ResponsibleSubjectComment) || activity_object.is_a?(::Legacy::Issues::ResponsibleSubjectInternalCommunication)
  end
end
