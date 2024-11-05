class SendIssueToZammadJob < ApplicationJob
  def perform(issue)
    client = ZammadAPI::Client.new(
      url:        ENV.fetch("OPS_ZAMMAD_URL"),
      http_token: ENV.fetch("OPS_ZAMMAD_API_TOKEN")
    )

    ticket = client.ticket.create(
      title: issue.title,
      state: "new",
      group: "Dobrovoľníci",
      customer: issue.author,
      customer_id: "guess:#{issue.author}",
      # anonymous: true,
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

    issue.last_synced = Time.now
    issue.zammad_id = ticket.id
    issue.save!
  end
end
