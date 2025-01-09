class Connector::ZammadApiClient
  def initialize(tenant, token: ENV.fetch("CONNECTOR__ZAMMAD_API_TOKEN"), url: ENV.fetch("CONNECTOR__ZAMMAD_URL"))
    @name = tenant.name
    @token = token
    @url = url
    @client = ZammadAPI::Client.new(url: @url, http_token: @token)
  end

  def client
    @client
  end

  def create_issue!(issue)
    article = issue["comments"].first

    tmp_body = {
      state: issue["state"],
      group: @name,
      title: issue["title"],
      origin_by: create_or_find_customer(issue["author"]),
      customer: create_or_find_customer(issue["author"]),
      triage_id: issue["triage_identifier"],
      article: {
        origin_by: create_or_find_customer(article["author"]),
        triage_id: article["triage_identifier"],
        content_type: article["content_type"],
        body: article["body"],
        type: article["type"],
        triage_created_at: article["created_at"],
        attachments: article["attachments"].map do |attachment|
          {
            filename: attachment["filename"],
            "mime-type": attachment["content_type"],
            data: attachment["data64"]
          }
        end
      }
    }

    new_ticket = @client.ticket.create(tmp_body)
    raise unless new_ticket.id

    return unless issue["comments"].count > 1

    issue["comments"][1..-1].each do |comment|
      new_article = new_ticket.article(
        origin_by: create_or_find_customer(comment["author"]),
        triage_id: comment["triage_identifier"],
        content_type: comment["content_type"],
        body: comment["body"],
        type: comment["type"],
        triage_created_at: comment["created_at"],
        attachments: comment["attachments"].map do |attachment|
          {
            filename: attachment["filename"],
            "mime-type": attachment["content_type"],
            data: attachment["data64"]
          }
        end
      )

      raise unless new_article.id
    end
  end

  def create_or_find_customer(author)
    email = "#{author['email_hash']}@ops.staging.slovensko.digital"
    begin
      @client.user.create(firstname: author["firstname"], lastname: author["lastname"], email: email)
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."
    end

    email
  end

  def create_comment!
    # TODO
  end
end
