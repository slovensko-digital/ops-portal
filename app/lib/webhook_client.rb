class WebhookClient
  def initialize(client)
    @client = client
  end

  def issue_created(issue_id)
    payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @client.id,
        issue_id: issue_id
      }
    }

    Triage::FireWebhookJob.perform_later(@client, Random.uuid, payload)
  end

  def activity_created(issue_id, activity_id)
    payload = {
      type: "activity.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @client.id,
        issue_id: issue_id,
        activity_id: activity_id
      }
    }

    Triage::FireWebhookJob.perform_later(@client, Random.uuid, payload)
  end

  def issue_updated(issue_id)
    payload = {
      type: "issue.updated",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @client.id,
        issue_id: issue_id
      }
    }

    Triage::FireWebhookJob.perform_later(@client, Random.uuid, payload)
  end
end
