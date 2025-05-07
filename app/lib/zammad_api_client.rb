class ZammadApiClient
  attr :client

  DEFAULT_SENDER = "Customer"
  DEFAULT_GROUP = "Incoming"
  DEFAULT_PROCESS_TYPE = "portal_issue_triage"
  DEFAULT_ARTICLE_TYPE = "web"
  DEFAULT_ORIGIN = "portal"
  DEFAULT_ARTICLE_CONTENT_TYPE = "text/html"
  USERS_PER_PAGE = 1000
  # TODO: consider seeding this value
  DEFAULT_OPS_ADMIN_USER = {
    firstname: "Dobrovoľník Odkazu pre starostu",
    lastname: "",
    uuid: "11111111-1111-1111-1111-111111111111"
  }
  RESPONSIBLE_SUBJECT_ARTICLE_TAG = TriageZammadEnvironment::RESPONSIBLE_SUBJECT_ARTICLE_TAG
  OPS_PORTAL_ARTICLE_TAG = TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG
  def initialize(url:, http_token:)
    @url = url
    @http_token = http_token
    @client = ZammadAPI::Client.new(url: url, http_token: http_token)
  end

  def get_ticket(ticket_id, expand: false, customer_articles: false, exclude_responsible_subject_articles: false, responsible_subject: nil)
    begin
      ticket = @client.ticket.find(ticket_id)
    rescue => e
      raise e unless e.message.include?("Couldn't find Ticket with")
      return
    end

    result = build_ticket_response(ticket)

    return unless result.present?
    return result unless expand

    result.merge({
      activities: [ build_article_response(ticket, ticket.articles.first, first_article: true) ] +
        ticket.articles[1..].map { |article|
          build_article_response(
            ticket,
            article,
            customer_articles: customer_articles,
            exclude_responsible_subject_articles: exclude_responsible_subject_articles,
            responsible_subject: responsible_subject
          )
        }.compact
    })
  end

  def create_ticket_from_issue!(issue, process_type: DEFAULT_PROCESS_TYPE, state: nil, group: DEFAULT_GROUP, sender: DEFAULT_SENDER, owner_id: nil)
    ticket = @client.ticket.create(
      process_type: process_type,
      issue_type: issue.issue_type,
      title: issue.title,
      body: issue.description,
      group: group,
      customer_id: issue.author.external_id,
      origin_by_id: issue.author.external_id,
      address_state: issue.address_region, # TODO rename this?
      address_county: issue.address_district, # TODO rename this?
      address_municipality: build_ticket_municipality(issue),
      address_postcode: issue.address_postcode,
      address_street: issue.address_street,
      address_house_number: issue.address_house_number,
      address_lat: issue.latitude,
      address_lon: issue.longitude,
      category: issue.category&.triage_external_id || issue.category&.name,
      subcategory: issue.subcategory&.name,
      subtype: issue.subtype&.name,
      state: state,
      ops_state: issue.state&.key,
      portal_url: Rails.application.routes.url_helpers.issue_url(issue),
      anonymous: issue.anonymous, # TODO add logic to handle legacy logic here (anonymous user)
      responsible_subject: {
        "label"=> issue.responsible_subject&.subject_name,
        "value"=> issue.responsible_subject&.id
      },
      owner_id: owner_id,
      created_at: issue.created_at,
      likes_count: issue.votes.count,
      origin: DEFAULT_ORIGIN,
      article: {
        origin_by_id: issue.author.external_id,
        body: issue.description.presence || "(bez popisu)",
        type: DEFAULT_ARTICLE_TYPE,
        attachments: issue.photos.map do |photo|
          {
            "filename" => photo.filename.to_s,
            "data" => Base64.encode64(photo.blob.download),
            "mime-type" => photo.content_type
          }
        end,
        sender: sender,
        created_at: issue.created_at
      },
    )

    # TODO custom error
    raise unless ticket.id
    ticket.id
  end

  def update_ticket!(ticket_id, ticket_params)
    ticket = @client.ticket.find(ticket_id)

    # TODO add more fields - this way?
    for key, value in ticket_params
      case key
      when "ops_state"
        ticket.ops_state = value
      when "responsible_subject"
        ticket.responsible_subject = value
      when "investment"
        ticket.investment = value
      end
    end

    ticket.save
  end

  def close_ticket!(ticket_id)
    ticket = @client.ticket.find(ticket_id)
    ticket.state = "closed"
    ticket.save
  end

  def update_ticket_from_issue!(ticket_id, issue)
    ticket = @client.ticket.find(ticket_id)

    likes_count = issue.legacy_data ? issue.legacy_data["like_count"] : 999 # TODO use issue.likes_count

    ticket.title = issue.title
    ticket.issue_type = issue.issue_type
    ticket.address_state = issue.address_region, # TODO rename this?
    ticket.address_county = issue.address_district, # TODO rename this?
    ticket.address_municipality = build_ticket_municipality(issue),
    ticket.address_postcode = issue.address_postcode,
    ticket.address_street = issue.address_street,
    ticket.address_house_number = issue.address_house_number,
    ticket.address_lat = issue.latitude,
    ticket.address_lon = issue.longitude,
    ticket.ops_state = issue.state.key
    ticket.likes_count = likes_count

    ticket.save

    # TODO check if it is always 1st article
    article = ticket.articles.first
    article.body = issue.description
    article.save
  end

  def get_article(ticket_id, article_id, customer_articles: true, responsible_subject: nil)
    begin
      ticket = @client.ticket.find(ticket_id)
      article = ticket.articles.find { |a| a.id == article_id.to_i }
    rescue RuntimeError => e
      raise e unless e.message.include?("Couldn't find Ticket with") || e.message.include?("Couldn't find Article with")
      Rails.logger.info("Couldn't find article with id: #{article_id} in ticket with id: #{ticket_id}")
      return
    end

    result = build_article_response(ticket, article, customer_articles: customer_articles, responsible_subject: responsible_subject)
    return unless result.present?
    result
  end

  def create_article!(issue_id, activity_object, sender:)
    ticket = @client.ticket.find(issue_id)

    article = ticket.article(
      origin_by_id: activity_object.author&.external_id,
      content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
      body: activity_object.triage_activity_body,
      type: DEFAULT_ARTICLE_TYPE,
      attachments: activity_object.attachments.map do |attachment|
        {
          "filename" => attachment.filename,
          "mime-type" => attachment.content_type,
          "data" => Base64.encode64(attachment.blob.download)
        }
      end,
      created_at: activity_object.created_at,
      sender: sender
    )

    # TODO custom error
    raise unless article.id
    article.id
  end

  def create_article_from_api!(author_id, issue_id, activity)
    ticket = @client.ticket.find(issue_id)

    article = ticket.article(
      origin_by_id: author_id,
      content_type: activity["content_type"],
      body: activity["body"],
      type: activity["type"],
      internal: false,
      attachments: activity["attachments"].map do |attachment|
        {
          "filename" => attachment["filename"],
          "mime-type" => attachment["content_type"],
          "data" => attachment["data64"]
        }
      end,
      created_at: activity["created_at"],
    )

    # TODO custom error
    raise unless article.id
    article.id
  end

  def create_internal_system_note!(ticket_id, body)
    ticket = @client.ticket.find(ticket_id)

    article = ticket.article(
      content_type: "text/plain",
      body: body,
      type: "note",
      internal: true,
      sender: "System"
    )

    # TODO custom error
    raise unless article.id
    article.id
  end

  def get_users
    @client.user.all
  end

  def get_user(identifier)
    @client.user.find identifier
  end

  def add_user_to_group(user_identifier, group_name)
    user = get_user(user_identifier)
    user_groups = user.groups
    user_groups[group_name] = "full"
    user.groups = user_groups

    user.save
  end

  def create_customer!(user)
    begin
      # TODO what if there is existing non-portal user?
      zammad_user = @client.user.create(
        firstname: user.display_name,
        roles: [ "Portal User" ],
        origin: "portal"
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e
    end
  end

  def create_agent!(user)
    begin
      zammad_user = @client.user.create(
        firstname: user.firstname,
        lastname: user.lastname,
        email: user.email,
        roles: [ "Agent" ]
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user(user.email)
      raise "Can't find nor create triage zammad user with email: #{user.email}" unless result
      result.id
    end
  end

  def create_responsible_subject!(responsible_subject)
    begin
      zammad_user = @client.user.create(
        firstname: responsible_subject.subject_name,
        roles: [ "Zodpovedný Subjekt" ]
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user(responsible_subject.subject_name)
      raise "Can't create triage zammad user for responsible subject: #{responsible_subject.subject_name}" unless result
      result.id
    end
  end

  def get_groups
    @client.group.all
  end

  def find_ticket_responsible_subject(ticket_id)
    @client.ticket.find(ticket_id).responsible_subject
  end

  def check_import_mode!
    response_body = raw_api_request(:get, "settings")
    import_mode_on = response_body.select { |attribute| attribute["name"] == "import_mode" }.first["state_current"]["value"]

    raise "Import mode OFF" unless import_mode_on
  end

  def link_tickets!(parent_ticket_id:, child_ticket_id:)
    child_ticket_number = @client.ticket.find(child_ticket_id).number
    raw_api_request(:post, "links/add", {
      link_type: "child",
      link_object_target: "Ticket",
      link_object_target_value: parent_ticket_id,
      link_object_source: "Ticket",
      link_object_source_number: child_ticket_number
    })
  end

  def raw_api_request(method, endpoint, params = {})
    url = File.join(@url, "api/v1/", endpoint)
    connection = Faraday.new(url: url) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :net_http
    end

    response = connection.send(method) do |req|
      req.headers["Authorization"] = "Token token=#{@http_token}"
      req.body = params.to_json unless params.empty?
    end
  rescue StandardError => error
    raise error.response if error.respond_to?(:response) && error.response
    raise error
  else
    raise "Request failed with status #{response.status}" unless response.status < 400

    response.body
  end

  private

  def find_zammad_user(query)
    # searches user by email, firstname, lastname and login
    @client.user.search(query: query).first
  end

  def find_zammad_user_by_id(id)
    @client.user.find(id)
  end

  def get_author(user_id, anonymous: false)
    return if anonymous

    user = find_or_create_user(user_id)
    {
      firstname: user.firstname,
      lastname: user.lastname,
      uuid: user.uuid
    } if user
  end

  def find_or_create_user(user_id)
    user = User.find_by(external_id: user_id)
    return user if user

    u = get_user(user_id)
    # TODO why are we creating a user from zammad in portal? this should never happen
    # TODO handle responsible subject users for portal

    return if u.id == ENV.fetch("TRIAGE_ZAMMAD_TECH_USER_ID").to_i

    User.create!(external_id: u.id, email: u.email, firstname: u.firstname, lastname: u.lastname)
  end

  def build_ticket_municipality(issue)
    if issue.municipality_district.present?
      "#{issue.municipality&.name}::#{issue.municipality_district.name}"
    else
      issue.municipality&.name
    end
  end

  def build_ticket_response(ticket)
    municipality_name, district_name = ticket.address_municipality.split("::", 2)
    municipality = Municipality.find_by!(name: municipality_name)
    municipality_district = municipality&.municipality_districts&.find_by(name: district_name)

    category = Issues::Category.find_by(name: ticket.category) || Issues::Category.find_by(triage_external_id: ticket.category)
    subcategory = category&.subcategories&.find_by!(name: ticket.subcategory)
    subtype = subcategory&.subtypes&.find_by(name: ticket.subtype)

    ops_state = Issues::State.find_by!(key: ticket.ops_state)

    responsible_subject = ResponsibleSubject.find_by(id: ticket.responsible_subject[:value])

    {
      triage_identifier: ticket.id,
      triage_group: ticket.group,
      triage_owner_id: ticket.owner_id,
      ops_state: ops_state,
      origin: ticket.origin,
      process_type: ticket.process_type,
      title: ticket.title,
      description: ticket.body,
      author: get_author(ticket.customer_id, anonymous: ticket.anonymous),
      responsible_subject: responsible_subject,
      issue_type: ticket.issue_type,
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      address_state: ticket.address_state,
      address_county: ticket.address_county,
      municipality: municipality,
      municipality_district: municipality_district,
      address_postcode: ticket.address_postcode,
      address_street: ticket.address_street,
      address_lat: ticket.address_lat,
      address_lon: ticket.address_lon,
      address_house_number: ticket.address_house_number,
      likes_count: ticket.likes_count,
      portal_url: ticket.portal_url,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at
    }
  end

  def build_article_response(ticket, article, customer_articles: true, exclude_responsible_subject_articles: false, responsible_subject: nil, first_article: false)
    return if article.internal

    customer_article = article_from_customer?(article)
    return if !customer_articles && customer_article

    article_without_author = article.origin_by_id == nil

    portal_article = article_for_portal?(article, ticket, first_article: first_article)
    return unless customer_article || portal_article || article_without_author || article_for_this_responsible_subject?(article, ticket, responsible_subject) || article_from_responsible_subject?(article, responsible_subject)

    responsible_subject_article = article.sender != "Agent" && customer_article == false
    return if exclude_responsible_subject_articles && responsible_subject_article

    if article.sender == "Agent"
      author = DEFAULT_OPS_ADMIN_USER
    else
      # TODO this anonymous logic is not correct as article.created_by is not always the same as article.origin_by
      author = get_author(
        article.origin_by_id || article.created_by_id,
        anonymous: (ticket.anonymous && article.created_by == ticket.customer)
      )
    end

    {
      author: author,
      triage_identifier: article.id,
      content_type: article.content_type,
      body: article.body.gsub(RESPONSIBLE_SUBJECT_ARTICLE_TAG, "").gsub(OPS_PORTAL_ARTICLE_TAG, ""),
      portal_activity: portal_article,
      customer_activity: customer_article,
      created_at: article.created_at,
      updated_at: article.updated_at,
      attachments: article.attachments.map do |attachment|
        {
          triage_identifier: attachment.id,
          filename: attachment.filename,
          content_type: attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type"),
          data64: Base64.strict_encode64(attachment.download)
        }
      end
    }
  end

  def article_for_portal?(article, ticket, first_article: false)
    return false if article.internal
    return true if first_article

    process_type = ticket.process_type
    case process_type
    when "portal_issue_triage"
      return true
    when "portal_issue_resolution"
      return true if article.body.include?(OPS_PORTAL_ARTICLE_TAG)
    end

    # TODO add support for other process types

    false
  end

  def article_from_customer?(article)
    return false if article.internal
    return false unless article.sender == "Customer"

    find_zammad_user_by_id(article.origin_by_id)&.origin == "portal" if article.origin_by_id
  end

  def article_from_responsible_subject?(article, responsible_subject)
    return false if article.internal
    return false unless article.sender == "Customer"

    find_zammad_user(article.origin_by)&.roles&.include?("Zodpovedný Subjekt")
  end

  def article_for_this_responsible_subject?(article, ticket, responsible_subject)
    return false unless responsible_subject
    return false unless article.body.include?(RESPONSIBLE_SUBJECT_ARTICLE_TAG)

    ticket.responsible_subject&.dig(:value)&.to_i == responsible_subject.id
  end
end
