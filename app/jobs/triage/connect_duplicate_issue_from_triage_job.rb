class Triage::ConnectDuplicateIssueFromTriageJob < ApplicationJob
  def perform(ticket, triage_zammad_client: TriageZammadEnvironment.client)
    @triage_zammad_client = triage_zammad_client
    issue = TriageUtils.get_issue_from_ticket(ticket)

    parent_ticket_ids = @triage_zammad_client.get_ticket_resolution_parent_links(ticket[:triage_identifier])
    valid_duplicate = valid_duplicate?(parent_ticket_ids, issue)
    ticket[:ops_state] = issue.state unless valid_duplicate
    Triage::UpdatePortalIssueFromTriageJob.perform_now(ticket)

    return if issue.state.key == "duplicate"

    if valid_duplicate
      accept_duplicate(ticket[:triage_identifier], issue, parent_ticket_ids)
    else
      reject_duplicate(ticket)
    end
  end

  private

  def accept_duplicate(ticket_id, issue, parent_ticket_ids)
    parent_ticket_id = parent_ticket_ids.last
    raise "No valid parent ticket found for duplicate issue" unless parent_ticket_id

    parent_ticket = @triage_zammad_client.get_ticket(parent_ticket_id)
    raise "Parent ticket not found" unless parent_ticket

    parent_issue = TriageUtils.get_issue_from_ticket(parent_ticket)
    raise "Parent issue not found" unless parent_issue

    @triage_zammad_client.create_system_note!(
      ticket_id,
      "[[ops portal]][[pre zodpovedny subjekt]] Podnet bol označený ako duplicitný. Jeho obsah bol pridaný ako komentár k pôvodnému podnetu: <a href=\"#{parent_ticket[:portal_url]}\" target=\"_blank\">##{parent_ticket[:ops_issue_identifier]} #{parent_ticket[:title]}</a>",
      content_type: "text/html",
      internal: false,
      sender: "Agent"
    )

    comment_params = {
      text: "Komentár vytvorený z duplicitného podnetu:\n\n" + issue.description,
      attachments: issue.photos.map do |photo|
        {
          io: StringIO.new(photo.download),
          content_type: photo.content_type,
          filename: photo.filename.to_s
        }
      end,
      user_author: issue.author
    }
    comment = Issues::DuplicateIssueComment.new(comment_params)
    comment.build_activity(issue: parent_issue, type: Issues::CommentActivity)
    comment.save!

    issue.subscriptions.each do |subscription|
      user = subscription.subscriber
      user.subscribe_to(parent_issue) unless user.subscribed_to?(parent_issue)
    end

    ::SyncIssueActivityObjectToTriageJob.perform_later(issue: parent_issue, activity_object: comment)
  end

  def reject_duplicate(ticket)
    @triage_zammad_client.update_ticket!(ticket[:triage_identifier], "ops_state" => ticket[:ops_state].key)
    @triage_zammad_client.create_system_note!(
      ticket[:triage_identifier],
      "Aby bol tento podnet označený ako duplicitný, musí byť k nemu nalinkovaný pôvodný podnet v procese Riešenie podnetu ako rodič.",
      internal: false
    )
  end

  def valid_duplicate?(parent_ticket_ids, issue)
    return false if parent_ticket_ids.empty?
    return true if parent_ticket_ids.count >= 2
    return true if issue.triage_external_id != parent_ticket_ids.first
    false
  end
end
