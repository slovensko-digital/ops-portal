module Connector
  class ZammadApiClient
    attr :client

    # TODO
    ANONYMOUS_USER_ID = 1
    DEFAULT_GROUP = "Incoming"
    DEFAULT_STATE = "new"
    OPS_ORIGIN = "ops"

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
        case key
        when "ops_state"
          ticket.ops_state = value
        when "responsible_subject"
          ticket.ops_responsible_subject = value
        when "responsible_subject_changed_at"
          ticket.ops_responsible_subject_changed_at = value
        when "likes_count"
          ticket.ops_likes_count = value
        when "category"
          ticket.ops_category = value
        when "subcategory"
          ticket.ops_subcategory = value
        when "subtype"
          ticket.ops_subtype = value
        when "address_municipality"
          ticket.address_municipality = value&.split("::").first
          ticket.address_municipality_district = value&.split("::").last
        when "address_street"
          ticket.address_street = value
        when "address_house_number"
          ticket.address_house_number = value
        when "address_postcode"
          ticket.address_postcode = value
        when "address_lat"
          ticket.address_lat = value
        when "address_lon"
          ticket.address_lon = value
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

      {
        ops_state: ticket.ops_state,
        responsible_subject: ticket.ops_responsible_subject,
        investment: ticket.investment
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
              content_type: attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type"),
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
        return user.external_id unless user.new_record?

        zammad_identifier = @client.user.create(firstname: author["firstname"], lastname: author["lastname"], login: author["uuid"]).id
        raise unless zammad_identifier
        user.update(firstname: author["firstname"], lastname: author["lastname"], external_id: zammad_identifier)
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
        state: DEFAULT_STATE,
        group: DEFAULT_GROUP,
        origin: OPS_ORIGIN,
        title: issue["title"],
        ops_state: issue["ops_state"],
        origin_by_id: create_or_find_customer(issue["author"]),
        customer_id: create_or_find_customer(issue["author"]),
        ops_issue_type: issue["issue_type"],
        ops_responsible_subject: issue["responsible_subject"],
        ops_category: issue["category"],
        ops_subcategory: issue["subcategory"],
        ops_subtype: issue["subtype"],
        address_municipality: issue["address_municipality"].split("::").first,
        address_municipality_district: issue["address_municipality"].split("::").last,
        address_street: issue["address_street"],
        address_house_number: issue["address_house_number"],
        address_postcode: issue["address_postcode"],
        address_lat: issue["address_lat"],
        address_lon: issue["address_lon"],
        ops_responsible_subject_changed_at: issue["responsible_subject_changed_at"],
        ops_likes_count: issue["likes_count"],
        ops_portal_url: issue["portal_url"],
        created_at: issue["created_at"],
        updated_at: issue["updated_at"],
        article: {
          origin_by_id: create_or_find_customer(article["author"]),
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
        content_type: activity["content_type"],
        body: activity["body"],
        type: activity["type"],
        internal: false,
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
