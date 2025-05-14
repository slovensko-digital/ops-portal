module Connector
  class ZammadApiClient
    attr :client

    # TODO
    ANONYMOUS_USER_ID = 1
    DEFAULT_GROUP = "Incoming"
    IMPORT_GROUP = "Stará verzia Odkaz pre starostu"
    DEFAULT_STATE = "new"
    DEFAULT_SENDER = "Customer"
    OPS_ORIGIN = "ops"
    DEFAULT_ARTICLE_CONTENT_TYPE = "text/html"
    DEFAULT_ARTICLE_TYPE = "note"
    DEFAULT_FIRST_ARTICLE_TYPE = "web"

    def initialize(tenant)
      @token = tenant.backoffice_api_token
      @url = tenant.backoffice_url
      @tenant = tenant
      @client = ZammadAPI::Client.new(url: @url, http_token: @token)
    end

    def create_issue!(issue, state: DEFAULT_STATE, group: DEFAULT_GROUP)
      ticket = find_or_create_ticket!(issue, state: state, group: group)

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
        investment: ticket.ops_investment
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

    def find_or_create_article_from_activity_object!(issue, activity_object, author_id: nil, internal:, sender:)
      ticket = find_ticket_for_issue!(issue)

      article = @tenant.activities.find_by(triage_external_id: activity_object.triage_external_id)
      return @client.ticket.find(ticket.id).articles.find { |a| article.backoffice_external_id == a.id } if article

      new_article = ticket.article(
        origin_by_id: author_id,
        content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
        body: activity_object.backoffice_activity_body,
        type: DEFAULT_ARTICLE_TYPE,
        internal: internal,
        triage_created_at: activity_object.created_at,
        attachments: activity_object.attachments.map do |attachment|
          {
            "filename" => attachment.filename,
            "mime-type" => attachment.content_type,
            "data" => Base64.encode64(attachment.blob.download)
          }
        end,
        sender: sender,
        created_at: activity_object.created_at
      )

      # TODO custom error
      raise unless new_article.id

      @tenant.activities.create!(triage_external_id: activity_object.triage_external_id, backoffice_external_id: new_article.id)
      new_article
    end

    def find_or_create_article_from_legacy_data!(legacy_data, tenant_issue, sender:)
      ticket = @client.ticket.find(tenant_issue.backoffice_external_id)

      article = @tenant.activities.find_by(legacy_id: legacy_data.id)
      return ticket.articles.find { |a| article.backoffice_external_id == a.id } if article

      new_article = ticket.article(
        origin_by_id: create_or_find_agent(legacy_data.author),
        content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
        body: legacy_data.body,
        type: DEFAULT_ARTICLE_TYPE,
        internal: legacy_data.internal,
        attachments: legacy_data.attachments.map do |attachment|
          {
            "filename" => attachment.filename,
            "mime-type" => attachment.mimetype,
            "data" => Base64.encode64(attachment.content)
          }
        end,
        sender: sender,
        created_at: legacy_data.created_at
      )

      raise unless new_article.id

      @tenant.activities.create!(legacy_id: legacy_data.id, backoffice_external_id: new_article.id)
      new_article
    end

    def find_or_create_ticket_from_legacy_data!(legacy_data, state:, group:)
      tenant_issue = @tenant.issues.find_by(legacy_id: legacy_data.id)
      return @client.ticket.find(tenant_issue.backoffice_external_id) if tenant_issue

      tmp_body = {
        state: state,
        group: group,
        title: legacy_data.title,
        ops_responsible_subject: {
          "label"=> legacy_data.responsible_subject&.subject_name,
          "value"=> legacy_data.responsible_subject&.id
        },
        ops_category: legacy_data.category&.name,
        ops_subcategory: legacy_data.subcategory&.name,
        ops_subtype: legacy_data.subtype&.name,
        address_municipality: legacy_data.municipality&.name,
        address_municipality_district: legacy_data.municipality_district.name,
        address_street: legacy_data.address_street,
        address_lat: legacy_data.latitude,
        address_lon: legacy_data.longitude,
        created_at: legacy_data.created_at,
        origin_by_id: create_or_find_agent(legacy_data.author),
        customer_id: create_or_find_agent(legacy_data.author),
        article: {
          body: legacy_data.description.presence || "(bez popisu)",
          type: DEFAULT_FIRST_ARTICLE_TYPE,
          internal: legacy_data.internal,
          attachments: legacy_data.attachments.map do |attachment|
            {
              "filename" => attachment.filename,
              "mime-type" => attachment.mimetype,
              "data" => Base64.encode64(attachment.content.read)
            }
          end,
          created_at: legacy_data.created_at
        }
      }

      new_ticket = @client.ticket.create(tmp_body)
      # TODO custom error
      raise unless new_ticket.id

      @tenant.issues.create!(legacy_id: legacy_data.id, backoffice_external_id: new_ticket.id)

      set_ticket_owner_from_legacy_data(new_ticket, legacy_data)
      set_ticket_subscribers_from_legacy_data(new_ticket, legacy_data)

      new_ticket
    end

    def set_ticket_owner_from_legacy_data(ticket, legacy_data)
      user_id = create_or_find_agent(legacy_data.owner)
      add_user_to_group(user_id, IMPORT_GROUP)

      ticket.owner_id = user_id
      ticket.save
    end

    def set_ticket_subscribers_from_legacy_data(ticket, legacy_data)
      legacy_data.subscribers.each do |subscriber|
        subscriber_id = create_or_find_agent(subscriber)
        mention_agent_in_ticket(subscriber_id, ticket)
      end
    end

    def set_ticket_owner(issue)
      ticket = find_ticket_for_issue!(issue)

      user_id = create_or_find_agent(issue.backoffice_owner)
      add_user_to_group(user_id, IMPORT_GROUP)

      ticket.owner_id = user_id
      ticket.save
    end

    def find_or_create_imported_article_agent_author(user)
      user_id = create_or_find_agent(user)
      add_user_to_group(user_id, IMPORT_GROUP)

      user_id
    end

    def subscribe_ticket(agent, issue)
      ticket = find_ticket_for_issue!(issue)

      agent_id = create_or_find_agent(agent)

      raise "Agent not found in backoffice!" unless agent_id

      mention_agent_in_ticket(agent_id, ticket)
    end

    def mention_agent_in_ticket(agent_id, ticket)
      add_user_to_group(agent_id, IMPORT_GROUP)

      _, response_status = raw_api_request(
        :post,
        "mentions",
        params: {
          mentionable_id: ticket.id,
          mentionable_type: "Ticket"
        },
        headers: {
          "From": agent_id.to_s
        }
      )

      raise "Ticket subscription not successful!" unless response_status == 201
    end

    def check_import_mode!
      response_body, _ = raw_api_request(:get, "settings")
      import_mode_on = response_body.select { |attribute| attribute["name"] == "import_mode" }.first["state_current"]["value"]

      raise "Import mode OFF" unless import_mode_on
    end

    private

    def create_or_find_customer(author)
      return ANONYMOUS_USER_ID unless author

      user = @tenant.users.find_or_initialize_by(uuid: author["uuid"])
      return user.external_id unless user.new_record?

      zammad_identifier = find_or_create_user!(
        firstname: author["firstname"],
        lastname: author["lastname"],
        login: author["uuid"],
        roles: [ "OPS User" ],
      ).id

      user.update(firstname: author["firstname"], lastname: author["lastname"], external_id: zammad_identifier)

      zammad_identifier
    end

    def create_or_find_agent(author)
      return ANONYMOUS_USER_ID unless author

      user = @tenant.users.find_or_initialize_by(email: author.email)
      return user.external_id unless user.new_record?

      zammad_identifier = find_or_create_user!(
        firstname: author.name,
        email: author.email,
        roles: [ "Agent" ],
        active: author.deleted_at.nil?
      ).id

      user.update(firstname: author.name, external_id: zammad_identifier)

      zammad_identifier
    end

    def find_zammad_user(query)
      # searches user by email, firstname, lastname and login
      @client.user.search(query: query).first
    end

    def find_or_create_user!(user_params)
      begin
        zammad_user = @client.user.create(user_params)
        zammad_user
      rescue RuntimeError => e
        raise e unless e.message.include? "is already used for another user."

        zammad_user = find_zammad_user(user_params["email"] || user_params["login"])
        raise "Can't find nor create zammad user with email: #{user_params["email"]}" unless zammad_user
        zammad_user
      end
    end

    def add_user_to_group(user_identifier, group_name)
      user = get_user(user_identifier)
      user_groups = user.groups
      user_groups[group_name] = "full"
      user.groups = user_groups

      user.save
    end

    def find_ticket_for_issue!(issue)
      ticket = @tenant.issues.find_by(triage_external_id: issue.triage_external_id)
      @client.ticket.find(ticket.backoffice_external_id)
    end

    def find_or_create_ticket!(issue, state:, group:)
      ticket = @tenant.issues.find_by(triage_external_id: issue["triage_identifier"])
      return @client.ticket.find(ticket.backoffice_external_id) if ticket

      article = issue["activities"].first
      tmp_body = {
        state: state,
        group: group,
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
          type: DEFAULT_FIRST_ARTICLE_TYPE,
          triage_created_at: article["created_at"],
          attachments: article["attachments"].map do |attachment|
            {
              "filename" => attachment["filename"],
              "mime-type" => attachment["content_type"],
              "data" => attachment["data64"]
            }
          end,
          sender: DEFAULT_SENDER,
          created_at: issue["created_at"]
        }
      }

      new_ticket = @client.ticket.create(tmp_body)
      # TODO custom error
      raise unless new_ticket.id

      @tenant.issues.create!(triage_external_id: issue["triage_identifier"], backoffice_external_id: new_ticket.id)
      new_ticket
    end

    def find_or_create_article!(ticket, activity, sender: DEFAULT_SENDER)
      article = @tenant.activities.find_by(triage_external_id: activity["triage_identifier"])
      return @client.ticket.find(ticket.id).articles.find { |a| article.backoffice_external_id == a.id } if article

      new_article = ticket.article(
        origin_by_id: create_or_find_customer(activity["author"]),
        content_type: activity["content_type"],
        body: activity["body"],
        type: DEFAULT_ARTICLE_TYPE,
        internal: false,
        triage_created_at: activity["created_at"],
        attachments: activity["attachments"].map do |attachment|
          {
            "filename" => attachment["filename"],
            "mime-type" => attachment["content_type"],
            "data" => attachment["data64"]
          }
        end,
        sender: sender,
        created_at: activity["created_at"]
      )

      # TODO custom error
      raise unless new_article.id

      @tenant.activities.create!(triage_external_id: activity["triage_identifier"], backoffice_external_id: new_article.id)
      new_article
    end

    def get_user(identifier)
      @client.user.find identifier
    end

    def raw_api_request(method, endpoint, params: {}, headers: {})
      url = File.join(@url, "api/v1/", endpoint)
      connection = Faraday.new(url: url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter :net_http
      end

      response = connection.send(method) do |req|
        req.headers.merge!(headers)
        req.headers["Authorization"] = "Token token=#{@token}"
        req.body = params.to_json unless params.empty?
      end
    rescue StandardError => error
      raise error.response if error.respond_to?(:response) && error.response
      raise error
    else
      raise "Request failed with status #{response.status}" unless response.status < 400

      [ response.body, response.status ]
    end
  end
end
