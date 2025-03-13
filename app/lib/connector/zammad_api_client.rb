module Connector
  class ZammadApiClient
    attr :client

    # TODO
    ANONYMOUS_USER_ID = 2
    DEFAULT_GROUP = "Incoming"

    def initialize(tenant)
      @token = tenant.backoffice_api_token
      @url = tenant.backoffice_url
      @tenant = tenant
      @client = ZammadAPI::Client.new(url: @url, http_token: @token)
    end

    def create_issue!(issue)
      ticket = find_or_create_ticket!(issue)

      issue["activities"][1..-1].each do |activity|
        find_or_create_article!(ticket, activity)
      end
    end

    def update_issue!(issue_id, issue_data)
      issue = @tenant.issues.find_by(triage_external_id: issue_id)
      raise "Issue not found" unless issue

      ticket = @client.ticket.find(issue.backoffice_external_id)
      for key, value in issue_data
        # TODO add more attributes
        case key
        when "state"
          ticket.state = value
        end
      end
      ticket.save
    end

    def create_activity!(issue_id, activity)
      issue = @tenant.issues.find_by(triage_external_id: issue_id)
      raise "Issue not found" unless issue

      ticket = @client.ticket.find(issue.backoffice_external_id)
      find_or_create_article!(ticket, activity)
    end

    def get_issue(issue_id)
      ticket = @client.ticket.find(issue_id)

      # TODO add more attributes
      {
        state: ticket.state
      }
    end

    def get_activity(ticket_id, activity_id)
      begin
        ticket = @client.ticket.find(ticket_id)
        article = ticket.articles.find { |a| activity_id == a.id.to_i }

        {
          content_type: article.content_type,
          body: article.body,
          type: article.type,
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

    def find_or_create_ticket!(issue)
      ticket = @tenant.issues.find_by(triage_external_id: issue["triage_identifier"])
      return @client.ticket.find(ticket.backoffice_external_id) if ticket

      article = issue["activities"].first
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

    def find_or_create_article!(ticket, activity)
      article = @tenant.activities.find_by(triage_external_id: activity["triage_identifier"])
      return @client.ticket.find(ticket.id).articles.find { |a| article.backoffice_external_id == a.id } if article

      new_article = ticket.article(
        origin_by_id: create_or_find_customer(activity["author"]),
        triage_identifier: activity["triage_identifier"],
        content_type: activity["content_type"],
        body: activity["body"],
        type: activity["type"],
        triage_created_at: activity["created_at"],
        attachments: activity["attachments"].map do |attachment|
          {
            "filename" => attachment["filename"],
            "mime-type" => attachment["content_type"],
            "data" => attachment["data64"]
          }
        end
      )

      # TODO custom error
      raise unless new_article.id

      @tenant.activities.create!(triage_external_id: activity["triage_identifier"], backoffice_external_id: new_article.id)
      new_article
    end
  end
end
