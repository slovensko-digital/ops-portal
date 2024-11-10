class SendIssueToZammadJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client)
    ticket = client.ticket.create(
      title: issue.title,
      state: "new",
      group: "Dobrovoľníci",
      customer: issue.author,
      customer_id: "guess:#{issue.author}",
      # anonymous: true, TODO: handle anonymous issues - email and name visible to triage zammad, invisible for municipality
      article: {
        content_type: "text/plain", # or text/html, if not given test/plain is used
        body: issue.description,
        sender: "Agent",
        type: "web"
        # attachments can be optional, data needs to be base64 encoded
        # attachments: [
        #   'filename' => 'some_file.txt',
        #   'data' => 'dGVzdCAxMjM=',
        #   'mime-type' => 'text/plain',
        # ],
      },
    )

    issue.last_synced_at = Time.now
    issue.triage_external_id = ticket.id
    issue.save!
  end
end
