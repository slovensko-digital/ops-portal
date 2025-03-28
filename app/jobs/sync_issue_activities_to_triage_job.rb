class SyncIssueActivitiesToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client, import: false)
    client.check_import_mode! if import

    issue.activities.includes(:activity_object).find_each do |activity|
      next if activity.activity_object.triage_external_id.present?

      find_or_create_triage_portal_user!(activity.activity_object.author, client) if activity.activity_object.author && !activity.activity_object.author&.external_id

      article_id = client.create_article!(issue.triage_external_id, activity.activity_object)

      raise unless article_id

      activity.activity_object.update!(
        triage_external_id: article_id
      )
    end
  end

  def find_or_create_triage_portal_user!(user, client, customer: true)
    return user if user.external_id

    user.external_id = if customer
     client.create_customer!(user)
    else
     client.create_agent!(user)
    end
    user.save!

    user
  end
end
