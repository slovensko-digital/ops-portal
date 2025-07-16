class Connector::Legacy::ImportBackofficeActivityFromTriageToBackofficeJob < ApplicationJob
  def perform(tenant, triage_issue_id, zammad_client: Connector::BackofficeZammadEnvironment.client(tenant))
    zammad_client.check_import_mode!

    tenant_responsible_subject = ::Client.find(tenant.ops_api_subject_identifier).responsible_subject

    issue = Issue.find_by(resolution_external_id: triage_issue_id)

    issue.activities.includes(:activity_object).find_each do |activity|
      next unless backoffice_activity?(activity.activity_object)

      raise "Activity not synced to triage! #{activity.id}" unless activity.activity_object.triage_external_id.present?

      author = activity.activity_object.backoffice_author

      author_id = if author&.responsible_subject == tenant_responsible_subject
        zammad_client.find_or_create_imported_article_agent_author(author)
      else
        zammad_client.find_or_create_inactive_responsible_subject_user(author&.responsible_subject)
      end

      zammad_client.find_or_create_article_from_activity_object!(issue, activity.activity_object, author_id: author_id, internal: activity.activity_object.internal?, sender: "Agent")
    end
  end

  private

  def backoffice_activity?(activity_object)
    activity_object.is_a?(::Issues::ResponsibleSubjectComment) || activity_object.is_a?(::Legacy::Issues::ResponsibleSubjectInternalCommunication)
  end
end
