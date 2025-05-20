class SyncIssueActivityObjectToTriageJob < ApplicationJob
  def perform(issue:, activity_object:, triage_group: nil, client: TriageZammadEnvironment.client, import: false)
    return if activity_object.triage_external_id.present?

    client.check_import_mode! if import

    find_or_create_triage_portal_user!(activity_object.author, client, user_group: triage_group) if activity_object.author && !activity_object.author.external_id

    external_id = issue.triage_process? ? issue.triage_external_id : issue.resolution_external_id
    article_id = client.create_article!(external_id, activity_object, sender: sender_type(activity_object))

    raise unless article_id

    activity_object.update!(
      triage_external_id: article_id
    )
  end

  def find_or_create_triage_portal_user!(user, client, user_group: nil)
    return user if user.external_id

    if user.is_a?(User)
      user.update!(external_id: client.create_customer!(user))
    elsif user.is_a?(Legacy::Agent)
      user.update!(external_id: client.create_agent!(user))
      client.add_user_to_group(user.external_id, user_group)
    elsif user.is_a?(::ResponsibleSubjects::User) && user.responsible_subject
      user.responsible_subject.update!(external_id: client.create_responsible_subject!(user.responsible_subject))
    elsif user.is_a?(::ResponsibleSubject)
      user.update!(external_id: client.create_responsible_subject!(user))
    end

    user
  end

  def sender_type(activity_object)
    case activity_object
    when Issues::AgentComment, Issues::AgentPrivateComment
      "Agent"
    when Legacy::Issues::AgentInternalCommunication
      "Agent"
    when Issues::UserComment, Issues::UserPrivateComment
      "Customer"
    when Issues::ResponsibleSubjectComment
      "Customer"
    when Issues::Update
      "Customer"
    when Legacy::Issues::ResponsibleSubjectInternalCommunication
      "Customer"
    else
      raise "Unknown activity object type: #{activity_object.class.name}"
    end
  end
end
