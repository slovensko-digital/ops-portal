module Connector
  class ZammadApiClient
    attr :client

    # TODO
    ANONYMOUS_USER_ID = 25
    DEFAULT_GROUP = "Incoming"

    def initialize(tenant)
      @triage_user_id = tenant.triage_user_id
      @token = tenant.api_token
      @url = tenant.url
      @tenant = tenant
      @client = ZammadAPI::Client.new(url: @url, http_token: @token)
    end

    def create_issue!(issue)
      ticket = find_or_create_ticket!(issue)

      issue["comments"][1..-1].each do |comment|
        find_or_create_article!(ticket, comment)
      end
    end

    def update_issue_status!(issue_id, issue_state)
      issue = @tenant.issues.find_by(triage_external_id: issue_id)
      raise "Issue not found" unless issue

      ticket = @client.ticket.find(issue.backoffice_external_id)
      ticket.state = issue_state
      ticket.save
    end

    def create_comment!(issue_id, comment)
      issue = @tenant.issues.find_by(triage_external_id: issue_id)
      raise "Issue not found" unless issue

      ticket = @client.ticket.find(issue.backoffice_external_id)
      find_or_create_article!(ticket, comment)
    end

    def get_issue_state(issue_id)
      ticket = @client.ticket.find(issue_id)
      ticket.state
    end

    private

    def create_or_find_customer(author)
      return ANONYMOUS_USER_ID unless author

      begin
        user = @tenant.users.find_or_initialize_by(uuid: author["uuid"])
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

    private

    def find_or_create_ticket!(issue)
      ticket = @tenant.issues.find_by(triage_external_id: issue["triage_identifier"])
      return @client.ticket.find(ticket.backoffice_external_id) if ticket

      article = issue["comments"].first
      tmp_body = {
        state: issue["state"],
        group: DEFAULT_GROUP,
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

      @tenant.issues.create!(triage_external_id: issue["triage_identifier"], backoffice_external_id: new_ticket.id)
      new_ticket
    end

    def find_or_create_article!(ticket, comment)
      article = @tenant.comments.find_by(triage_external_id: comment["triage_identifier"])
      return @client.ticket.find(ticket.id).articles.find { |a| article.backoffice_external_id == a.id } if article

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

      @tenant.comments.create!(triage_external_id: comment["triage_identifier"], backoffice_external_id: new_article.id)
      new_article
    end
  end
end
