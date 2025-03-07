class ZammadApiClient
  attr :client

  DEFAULT_GROUP = "Incoming"
  DEFAULT_ARTICLE_TYPE = "web"
  DEFAULT_ARTICLE_CONTENT_TYPE = "text/html"
  USERS_PER_PAGE = 1000

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

  def get_article(ticket_id, article_id)
    begin
      ticket = @client.ticket.find(ticket_id)
      article = ticket.articles.find { |a| a.id == article_id }&.attributes

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

    rescue RuntimeError => e
      raise e unless e.message.include? "Couldn't find Ticket with"
    end
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

  def update_ticket_status(issue_id, status, responsible_subject_zammad_identifier)
    ticket = @client.ticket.find(issue_id)
    raise unless responsible_subject_zammad_identifier == ticket.responsible_subject

    ticket.state = status
    ticket.save
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
end
