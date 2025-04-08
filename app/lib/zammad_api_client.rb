class ZammadApiClient
  attr :client

  DEFAULT_GROUP = "Incoming"
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
  RESPONSIBLE_SUBJECT_ARTICLE_TAG = ENV.fetch("RESPONSIBLE_SUBJECT_ARTICLE_TAG", "[[pre zodpovedny subjekt]]")
  OPS_PORTAL_ARTICLE_TAG = ENV.fetch("OPS_PORTAL_ARTICLE_TAG", "[[ops portal]]")

  def initialize(url:, http_token:)
    @client = ZammadAPI::Client.new(url: url, http_token: http_token)
  end

  def get_ticket(ticket_id, include_customer_articles: false, expand: false)
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
      activities: [ build_article_response(ticket, ticket.articles.first, force: true) ] +
        ticket.articles[1..].map { |article| build_article_response(ticket, article, force: include_customer_articles) }.compact
    })
  end

  def create_ticket_from_issue!(issue, process_type:, issue_type:, title:, description:, portal_url:, responsible_subject:, likes_count:, group: DEFAULT_GROUP)
    ticket = @client.ticket.create(
      process_type: process_type,
      issue_type: issue_type,
      title: title,
      group: group,
      customer_id: issue.author.external_id,
      origin_by_id: issue.author.external_id,
      address_state: issue.address_state,
      address_county: issue.address_county,
      address_municipality: build_ticket_municipality(issue),
      address_postcode: issue.address_postcode,
      address_street: issue.address_street,
      address_house_number: issue.address_house_number,
      address_lat: issue.latitude,
      address_lon: issue.longitude,
      category: issue.category&.triage_external_id || issue.category.name,
      subcategory: issue.subcategory&.name,
      subtype: issue.subtype&.name,
      ops_state: issue.state.key,
      portal_url: portal_url,
      anonymous: issue.anonymous, # TODO add logic to handle legacy logic here (anonymous user)
      responsible_subject: {
        "label"=> responsible_subject&.subject_name,
        "value"=> responsible_subject&.id
      },
      owner_id: issue.owner&.external_id,
      created_at: issue.reported_at,
      likes_count: likes_count,
      origin: DEFAULT_ORIGIN,
      article: {
        origin_by_id: issue.author.external_id,
        body: description,
        type: DEFAULT_ARTICLE_TYPE,
        attachments: issue.photos.map do |photo|
          {
            "filename" => photo.filename.to_s,
            "data" => Base64.encode64(photo.blob.download),
            "mime-type" => photo.content_type
          }
        end,
        created_at: issue.reported_at
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

  def update_ticket_from_issue!(ticket_id, issue, title:, likes_count:)
    ticket = @client.ticket.find(ticket_id)

    ticket.title = title
    ticket.municipality = build_ticket_municipality(issue)
    ticket.address_lat = issue.latitude
    ticket.address_lon = issue.longitude
    ticket.address_county = issue.address_county
    ticket.address_city = issue.address_city
    ticket.address_city_district = issue.address_city_district
    ticket.address_postcode = issue.address_postcode
    ticket.address_suburb = issue.address_suburb
    ticket.address_village = issue.address_village
    ticket.address_town = issue.address_town
    ticket.address_street =  issue.address_street
    ticket.address_house_number = issue.address_house_number
    ticket.ops_state = issue.state.key
    ticket.likes_count = likes_count

    ticket.save

    # TODO check if it is always 1st article
    article = ticket.articles.first
    article.body = issue.description
    article.save
  end

  def get_article(ticket_id, article_id)
    begin
      ticket = @client.ticket.find(ticket_id)
      article = ticket.articles.find { |a| a.id == article_id.to_i }
    rescue RuntimeError => e
      raise e unless e.message.include?("Couldn't find Ticket with") || e.message.include?("Couldn't find Article with")
      Rails.logger.info("Couldn't find article with id: #{article_id} in ticket with id: #{ticket_id}")
      return
    end

    result = build_article_response(ticket, article)
    return unless result.present?
    result
  end

  def create_article!(issue_id, activity_object)
    ticket = @client.ticket.find(issue_id)

    article = ticket.article(
      origin_by_id: activity_object.author&.external_id,
      content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
      body: activity_object.activity_body,
      type: "web",
      attachments: activity_object.attachments.map do |attachment|
        {
          "filename" => attachment.filename,
          "mime-type" => attachment.content_type,
          "data" => Base64.encode64(attachment.blob.download)
        }
      end,
      created_at: activity_object.added_at,
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
        firstname: user.firstname,
        lastname: user.lastname,
        email: user.email,
        roles: [ "Portal User" ],
        origin: "portal"
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user(user.email)
      raise "Can't find nor create triage zammad user with email: #{user.email}" unless result
      result
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
      result
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
      raise "Can't create triage zammad user for responsible subject email: #{responsible_subject.subject_name}"
    end
  end

  def get_groups
    @client.group.all
  end

  def find_ticket_responsible_subject(ticket_id)
    @client.ticket.find(ticket_id).responsible_subject
  end

  def check_import_mode!
    response = Faraday.get("#{ENV.fetch("TRIAGE_ZAMMAD_URL")}api/v1/settings", {}, "Authorization": "Token token=#{ENV.fetch("TRIAGE_ZAMMAD_API_TOKEN")}")
    response_body = response.body.empty? ? nil : JSON.parse(response.body)
  rescue StandardError => error
    raise error.response if error.respond_to?(:response) && error.response
    raise error
  else
    raise "Unexpected status: #{response.status}" unless response.status == 200

    import_mode_on = response_body.select { |attribute| attribute["name"] == "import_mode" }.first["state_current"]["value"]

    raise "Import mode OFF" unless import_mode_on
  end

  private

  def find_zammad_user(email)
    # TODO use @client.user.search
    (1..).each do |page|
      users_on_page = @client.user.all.page(page, USERS_PER_PAGE) { }.map { |user| { email: user.attributes[:email], id: user.attributes[:id] } }
      zammad_user = users_on_page.select { |user| email == user[:email] }.first

      return zammad_user[:id] if zammad_user
      return unless users_on_page == USERS_PER_PAGE
    end
  end

  def get_author(user_id, anonymous: false)
    return if anonymous

    user = find_or_create_user(user_id)
    {
      firstname: user.firstname,
      lastname: user.lastname,
      uuid: user.uuid
    }
  end

  def find_or_create_user(user_id)
    user = User.find_by(external_id: user_id)
    return user if user

    u = get_user(user_id)
    # TODO why are we creating a user from zammad in portal? this should never happen
    User.create!(external_id: u.id, email: u.email, firstname: u.firstname, lastname: u.lastname)
  end

  def find_zammad_category(issue_category)
    issue_category.triage_external_id || issue_category.name
  end

  def build_ticket_municipality(issue)
    if issue.municipality_district.present?
      "#{issue.municipality&.name}::#{issue.municipality_district.name}"
    else
      issue.municipality&.name
    end
  end

  def build_ticket_response(ticket)
    {
      triage_identifier: ticket.id,
      ops_state: ticket.ops_state,
      title: ticket.title,
      author: get_author(ticket.customer_id, anonymous: ticket.anonymous),
      responsible_subject: ResponsibleSubject.find(ticket.responsible_subject[:value]),
      issue_type: ticket.issue_type,
      category: ticket.category,
      subcategory: ticket.subcategory,
      subtype: ticket.subtype,
      address_municipality: ticket.address_municipality,
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

  def build_article_response(ticket, article, force: false, system: false)
    # hide all internal articles
    return if article.internal

    # TODO revise this logic based on SGI feedback - BA-02 in DFS

    responsible_subject_tag = article.body.include?(RESPONSIBLE_SUBJECT_ARTICLE_TAG)
    ops_portal_tag = article.body.include?(OPS_PORTAL_ARTICLE_TAG)

    # hide all agent public articles without a tag
    return if article.sender == "Agent" && !responsible_subject_tag && !ops_portal_tag

    return unless force || responsible_subject_tag

    if article.sender == "Agent"
      author = DEFAULT_OPS_ADMIN_USER
    else
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
      type: article.type,
      customer_activity: !responsible_subject_tag,
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
end
