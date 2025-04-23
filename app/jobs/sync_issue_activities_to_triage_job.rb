class SyncIssueActivitiesToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client, import: false)
    client.check_import_mode! if import

    issue.activities.includes(:activity_object).find_each do |activity|
      next if activity.activity_object.triage_external_id.present?

      find_or_create_triage_portal_user!(activity.activity_object.author, client) if activity.activity_object.author && !activity.activity_object.author&.external_id

      article_id = client.create_article!(issue.triage_external_id, activity.activity_object, sender: sender_type(activity.activity_object.author))

      raise unless article_id

      activity.activity_object.update!(
        triage_external_id: article_id
      )
    end
  end

  def find_or_create_triage_portal_user!(user, client)
    return user if user.external_id

    if user.is_a?(User)
      user.update!(external_id: client.create_customer!(user))
    elsif user.is_a?(Legacy::Agent)
      user.update!(external_id: client.create_agent!(user))
    elsif user.is_a?(::ResponsibleSubjects::User) && user.responsible_subject
      user.responsible_subject.update!(external_id: client.create_responsible_subject!(user.responsible_subject))
    elsif user.is_a?(::ResponsibleSubject)
      user.update!(external_id: client.create_responsible_subject!(user))
    end

    user
  end

  def sender_type(user)
    if user.is_a?(User)
      "Customer"
    elsif user.is_a?(Legacy::Agent) || user.is_a?(::ResponsibleSubjects::User) || user.is_a?(::ResponsibleSubject)
      "Agent"
    else
      raise "Unknown author type: #{user.class.name}"
    end
  end
end
