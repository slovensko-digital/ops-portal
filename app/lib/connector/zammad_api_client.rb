class Connector::ZammadApiClient
  attr :client

  # TODO
  ANONYMOUS_USER_ID = 25

  def initialize(tenant, token: ENV.fetch("CONNECTOR__ZAMMAD_API_TOKEN"), url: ENV.fetch("CONNECTOR__ZAMMAD_URL"))
    @name = tenant.name
    @triage_user_id = tenant.triage_user_id
    @token = token
    @url = url
    @client = ZammadAPI::Client.new(url: @url, http_token: @token)
  end

  def create_issue!(issue)
    # TODO custom error
    raise RuntimeError.new("Issue with triage_external_id: #{issue.id} already exists.") if Connector::Issue.find_by(triage_external_id: issue.id)

    article = issue["comments"].first
    tmp_body = {
      state: issue["state"],
      group: @name,
      title: issue["title"],
      origin_by_id: create_or_find_customer(issue["author"]),
      customer_id: create_or_find_customer(issue["author"]),
      triage_identifier: issue["triage_identifier"],
      article: {
        origin_by_id: create_or_find_customer(article["author"]),
        triage_identifier: article["triage_identifier"],
        content_type: article["content_type"],
        body: article["body"],
        type: article["type"],
        triage_created_at: article["created_at"],
        attachments: article["attachments"].map do |attachment|
          {
            "filename" => attachment["filename"],
            "mime-type" => attachment["content_type"],
            "data" => attachment["data64"]
          }
        end
      }
    }

    new_ticket = @client.ticket.create(tmp_body)
    # TODO custom error
    raise unless new_ticket.id

    Connector::Issue.create!(triage_external_id: issue.id, backoffice_external_id: new_ticket.id)

    return unless issue["comments"].count > 1

    issue["comments"][1..-1].each do |comment|
      create_comment_for_ticket!(new_ticket, comment)
    end
  end

  def get_issue(ticket_id)
    @client.ticket.find(ticket_id)
  end

  def create_comment!(issue_id, comment)
    ticket = @client.ticket.find(Connector::Issue.find_by(triage_external_id: issue_id)&.backoffice_external_id)
    create_comment_for_ticket!(ticket, comment)
  end

  private

  def create_or_find_customer(author)
    return ANONYMOUS_USER_ID unless author

    begin
      user = Connector::User.find_or_initialize_by(uuid: author["uuid"])
      return user.zammad_identifier unless user.new_record?

      zammad_identifier = @client.user.create(firstname: author["firstname"], lastname: author["lastname"], login: author["uuid"]).id
      raise unless zammad_identifier
      user.update(firstname: author["firstname"], lastname: author["lastname"], zammad_identifier: zammad_identifier)
    rescue RuntimeError => e
      # TODO custom error
      raise e unless e.message.include? "is already used for another user."
    end

    zammad_identifier
  end

  def create_comment_for_ticket!(ticket, comment)
    # TODO custom error
    raise RuntimeError.new("Comment with triage_external_id: #{comment.id} already exists.") if Connector::Comment.find_by(triage_external_id: comment.id)

    new_article = ticket.article(
      origin_by_id: create_or_find_customer(comment["author"]),
      triage_identifier: comment["triage_identifier"],
      content_type: comment["content_type"],
      body: comment["body"],
      type: comment["type"],
      triage_created_at: comment["created_at"],
      attachments: comment["attachments"].map do |attachment|
        {
          "filename" => attachment["filename"],
          "mime-type" => attachment["content_type"],
          "data" => attachment["data64"]
        }
      end
    )

    # TODO custom error
    raise unless new_article.id

    Connector::Comment.create!(triage_external_id: comment.id, backoffice_external_id: new_article.id)
  end

  def get_comment(ticket_id, comment_id)
    begin
      ticket = @client.ticket.find(ticket_id)
      article = ticket.articles.find { |a| comment_id == a.id }&.attributes

      {
        author: @triage_user_id,
        content_type: article.content_type,
        body: article.body,
        type: article.type,
        created_at: article.created_at,
        updated_at: article.updated_at,
        attachments: article.attachments.map do |attachment|
          {
            filename: attachment.filename,
            content_type: attachment.preferences.dig(:"Mime-Type"),
            data64: Base64.strict_encode64(attachment.download)
          }
        end
      }

    rescue RuntimeError => e
      raise e unless e.message.include? "Couldn't find Ticket with"
    end
  end
end
