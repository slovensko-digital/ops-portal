class ZammadApiClient
  attr :client

  DEFAULT_GROUP = "Incomming"
  DEFAULT_ARTICLE_TYPE = "web"

  def initialize(url:, http_token:)
    @client = ZammadAPI::Client.new(url: url, http_token: http_token)
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
              content_type: attachment.preferences.dig(:"Mime-Type"),
              data64: Base64.strict_encode64(attachment.download)
            }
          end
        }
      end
    }

    result
  end

  def create_ticket(issue)
    ticket = @client.ticket.create(
      title: issue.title,
      group: DEFAULT_GROUP,
      customer_id: issue.author.zammad_identifier,
      origin_by_id: issue.author.zammad_identifier,
      municipality: issue.municipality,
      category: find_zammad_category(issue.category),
      anonymous: issue.anonymous,
      article: {
        origin_by_id: issue.author.zammad_identifier,
        body: issue.description,
        type: DEFAULT_ARTICLE_TYPE,
        attachments: issue.photos.map do |photo|
          {
            "filename" => photo.filename.to_s,
            "data" => Base64.encode64(photo.blob.download),
            "mime-type" => photo.content_type
          }
        end
      },
    )

    ticket.id
  end

  def get_users
    @client.user.all
  end

  def get_user(identifier)
    @client.user.find identifier
  end

  def find_ticket_responsible_subject(ticket_id)
    @client.ticket.find(ticket_id).responsible_subject
  end

  def update_ticket_status(issue_id, status, responsible_subject_zammad_identifier)
    ticket = @client.ticket.find(issue_id)
    raise unless responsible_subject_zammad_identifier == ticket.responsible_subject

    ticket.state = status
    ticket.save
  end

  private

  def create_or_find_customer(author_email)
    begin
      @client.user.create(email: author_email)
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."
    end

    author_email
  end

  def get_author(user_id, anonymous: false)
    return nil if anonymous

    user = find_or_create_user(user_id)
    {
      firstname: user.firstname,
      lastname: user.lastname,
      uuid: user.uuid
    }
  end

  def find_or_create_user(user_id)
    user = User.find_by(zammad_identifier: user_id)
    return user if user

    u = get_user(user_id)
    User.create!(zammad_identifier: u.id, email: u.email, firstname: u.firstname, lastname: u.lastname)
  end

  def find_zammad_category(issue_category)
    # TODO: do something real
    "1"
  end
end
