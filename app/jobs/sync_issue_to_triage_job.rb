class SyncIssueToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    # TODO actually do a sync (insert/update & handle triage_process/resolution_process)
    find_or_create_triage_portal_user!(issue.author, client) unless issue.author.zammad_identifier

    ticket_id = client.create_ticket!(issue)

    raise unless ticket_id

    issue.last_synced_at = Time.now
    issue.triage_external_id = ticket_id
    issue.save!
  end

  def find_or_create_triage_portal_user!(user, client)
    return user if user.zammad_identifier

    user.zammad_identifier = client.create_customer!(user)
    user.save!

    user
  end
end
