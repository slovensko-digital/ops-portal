class ZammadApiClient
  attr :client

  DEFAULT_GROUP = "Incoming"
  DEFAULT_ARTICLE_TYPE = "web"
  DEFAULT_ARTICLE_CONTENT_TYPE = "text/html"
  USERS_PER_PAGE = 1000

  def initialize(url:, http_token:)
    @client = ZammadAPI::Client.new(url: url, http_token: http_token)
  end

  def get_ticket(ticket_id, expand: false)
    begin
      ticket = @client.ticket.find(ticket_id)
    rescue => e
      raise e unless e.message.include?("Couldn't find Ticket with")
      return nil
    end

    result = build_ticket_response(ticket)

    return nil unless result.present?
    return result unless expand

    result.merge({
      activities: [ build_article_response(ticket, ticket.articles.first, first_article: true) ] +
        ticket.articles[1..].map { |article| build_article_response(ticket, article) }.compact
    })
  end

  def create_ticket!(issue, group: DEFAULT_GROUP)
    ticket = @client.ticket.create(
      title: issue.title,
      group: group,
      customer_id: issue.author.zammad_identifier,
      origin_by_id: issue.author.zammad_identifier,
      municipality: build_ticket_municipality(issue),
      street: issue.street&.name,
      category: find_zammad_category(issue.category),  # TODO add subcategory and subtype once implemented in triage
      state: issue.state.name,
      anonymous: issue.anonymous,
      responsible_subject: issue.responsible_subject&.legacy_id,  # TODO map to responsible_subjects in triage
      owner_id: issue.owner&.zammad_identifier,
      created_at: issue.reported_at,
      like_count: issue.legacy_data["like_count"],
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

    # TODO add more fields
    for key, value in ticket_params
      case key
      when "state"
        ticket.state = value
      end
    end

    ticket.save
  end

  def get_article(ticket_id, article_id)
    begin
      ticket = @client.ticket.find(ticket_id)
      article = ticket.articles.find { |a| a.id == article_id.to_i }
    rescue RuntimeError => e
      raise e unless e.message.include?("Couldn't find Ticket with") || e.message.include?("Couldn't find Article with")
      puts "Couldn't find article with id: #{article_id} in ticket with id: #{ticket_id}"
      return nil
    end

    result = build_article_response(ticket, article)
    return nil unless result.present?
    result
  end

  def create_article!(issue_id, activity_object)
    ticket = @client.ticket.find(issue_id)

    article = ticket.article(
      origin_by_id: activity_object.author&.zammad_identifier,
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

  def create_article_from_api!(triage_external_author_identifier, issue_id, activity)
    ticket = @client.ticket.find(issue_id)

    article = ticket.article(
      origin_by_id: triage_external_author_identifier,
      content_type: activity["content_type"],
      body: activity["body"],
      type: activity["type"],
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

  def create_customer!(email)
    begin
      zammad_user = @client.user.create(email: email)
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user email
      raise "Can't find nor create triage zammad user with email: #{email}" unless result
      result
    end
  end

  def create_agent!(email)
    begin
      zammad_user = @client.user.create(email: email, roles: [ "Agent" ])
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user email
      raise "Can't find nor create triage zammad user with email: #{email}" unless result
      result
    end
  end

  def get_groups
    @client.group.all
  end

  def find_ticket_responsible_subject(ticket_id)
    @client.ticket.find(ticket_id).responsible_subject
  end

  private

  def find_zammad_user(email)
    (1..).each do |page|
      users_on_page = @client.user.all.page(page, USERS_PER_PAGE) { }.map { |user| { email: user.attributes[:email], id: user.attributes[:id] } }
      zammad_user = users_on_page.select { |user| email == user[:email] }.first

      return zammad_user[:id] if zammad_user
      return nil unless users_on_page == USERS_PER_PAGE
    end
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
    issue_category.triage_external_id
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
      state: ticket.state,
      title: ticket.title,
      author: get_author(ticket.customer_id, anonymous: ticket.anonymous),
      responsible_subject_identifier: ticket.responsible_subject,
      issue_type: ticket.issue_type,
      category: ticket.category,
      subcategory: ticket.subcategory,
      subtype: ticket.subtype,
      address_state: ticket.address_state,
      address_county: ticket.address_county,
      address_city: ticket.address_city || ticket.address_village,
      address_city_district: ticket.address_city_district,
      address_suburb: ticket.address_suburb,
      address_road: ticket.address_road,
      address_house_number: ticket.address_house_number,
      likes_count: ticket.likes_count,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at
    }
  end

  def build_article_response(ticket, article, first_article: false)
    return nil unless first_article || article.body.include?("[[zodpovedny]]")

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
end
