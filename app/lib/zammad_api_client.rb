class ZammadApiClient
  def initialize(url:, http_token:)
    @client = ZammadAPI::Client.new(url: url, http_token: http_token)
  end

  def client
    @client
  end

  def get_ticket(ticket_id)
    begin
      ticket = @client.ticket.find(ticket_id)
    rescue => e
      Rails.logger.debug("Failed to get ticket with an error: #{e}")
      return nil
    end

    result = {
      triage_identifier: ticket.id,
      state: ticket.state,
      title: ticket.title,
      author: get_author(ticket.customer_id, anonymous: ticket.anonymous),
      responsible_subject_identifier: ticket.responsible_subject,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at,
      comments: ticket.articles.map do |article|
        {
          author: get_author(article.origin_by_id || article.created_by_id, anonymous: (ticket.anonymous && article.created_by == ticket.customer)),
          triage_identifier: article.id,
          content_type: article.content_type,
          body: article.body,
          type: article.type,
          created_at: article.created_at,
          updated_at: article.updated_at,
          attachments: article.attachments.map do |attachment|
            {
              triage_identifier: attachment.id,
              filename: attachment.filename,
              content_type: attachment.preferences.dig(:"Content-Type"),
              data64: Base64.strict_encode64(attachment.download)
            }
          end
        }
      end
    }

    result
  end

  def create_ticket(issue)
    create_or_find_customer(issue.author)
    ticket = @client.ticket.create(
      title: issue.title,
      group: "Incomming",
      customer: issue.author,
      origin_by: issue.author,
      municipality: "Bratislava::Staré Mesto",
      category: 1,
      # anonymous: true, TODO: handle anonymous issues - email and name visible to triage zammad, invisible for municipality
      article: {
        origin_by: issue.author,
        content_type: "text/plain", # or text/html, if not given test/plain is used
        body: issue.description,
        type: "web"
        # attachments can be optional, data needs to be base64 encoded
        # attachments: [
        #   'filename' => 'some_file.txt',
        #   'data' => 'dGVzdCAxMjM=',
        #   'mime-type' => 'text/plain',
        # ],
      },
    )

    ticket.id
  end

  def create_or_find_customer(author_email)
    begin
      @client.user.create(email: author_email)
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."
    end

    author_email
  end

  private

  def get_author(user_id, anonymous: false)
    begin
      user_object = @client.user.find(user_id)
      {
        firstname: anonymous ? "Anonymous" : user_object.firstname,
        lastname: anonymous ? "" : user_object.lastname,
        email_hash: OpenSSL::Digest::SHA256.hexdigest(user_object.email)
      }
    rescue => e
      Rails.logger.debug("Failed to get author info with an error: #{e}")
      nil
    end
  end
end
