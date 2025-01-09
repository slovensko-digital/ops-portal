class WebhookClient
  def initialize(backoffice_client)
    @backoffice_client = backoffice_client
  end

  def issue_created(issue_id)
    payload = {
      type: "issue.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @backoffice_client.id,
        issue_id: issue_id
      }
    }

    Triage::FireWebhookJob.perform_later(@backoffice_client, Random.uuid, payload)
  end

  def comment_created(issue_id, comment_id)
    payload = {
      type: "comment.created",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @backoffice_client.id,
        issue_id: issue_id,
        comment_id: comment_id
      }
    }

    Triage::FireWebhookJob.perform_later(@backoffice_client, Random.uuid, payload)
  end

  def issue_status_updated(issue_id, comment_id)
    payload = {
      type: "issue.status_updated",
      timestamp: Time.now.to_i,
      data: {
        subject_id: @backoffice_client.id,
        issue_id: issue_id
      }
    }

    Triage::FireWebhookJob.perform_later(@backoffice_client, Random.uuid, payload)
  end
end
