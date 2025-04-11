# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  require_relative "seeds/ai_prompts"

  webhook_url = "http://localhost:3000/connector/webhook"
  default_connector_zammad_api_token = "CsnpmnPAlMZCmbaClOoWE7QlFPgCsElVLsfgkJMZQfs"
  default_connector_zammad_webhook_secret = "6fvpqr777ryN9FTqkRH2xYGWFXU1W862R6NUyhQOErN"

  [
    {
      name: "MÚ Staré Mesto",
      pro: true,
      url: webhook_url,
      connector_zammad_url: "http://localhost:8081/",
      connector_zammad_api_token: default_connector_zammad_api_token,
      connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
    },
    {
      name: "Hlavné mesto SR Bratislava",
      pro: true,
      url: webhook_url,
      connector_zammad_url: "http://localhost:8082/",
      connector_zammad_api_token: default_connector_zammad_api_token,
      connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
    },
    {
      name: "MÚ Nové Mesto",
      pro: false
    }
  ].each do |data|
    responsible_subject_type = ResponsibleSubjects::Type.find_or_create_by!(name: "Mestský úrad")
    responsible_subject = ResponsibleSubject.find_or_create_by!(name: data[:name], responsible_subjects_type_id: responsible_subject_type.id)
    responsible_subject.update_columns(
      subject_name: data[:name],
      active: true,
      pro: data[:pro]
    )

    next unless data[:pro]

    client = Client.find_or_create_by!(name: data[:name])
    tenant = Connector::Tenant.find_or_create_by!(name: data[:name])

    api_key = OpenSSL::PKey::EC.generate("prime256v1")
    webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

    client.update_columns(
      api_token_public_key: api_key.public_to_pem,
      webhook_private_key: webhook_key.to_pem,
      url: data[:url],
      responsible_subject_id: responsible_subject.id
    )

    tenant.update_columns(
      backoffice_api_token: data[:connector_zammad_api_token],
      backoffice_webhook_secret: data[:connector_zammad_webhook_secret],
      ops_api_token_private_key: api_key.to_pem,
      ops_webhook_public_key: webhook_key.public_to_pem,
      ops_api_subject_identifier: client.id,
      backoffice_url: data[:connector_zammad_url]
    )
  end
end

[
  {
    name: "Zaslaný zodpovednému",
    key: "sent_to_responsible"
  },
  {
    name: "Odstúpený",
    key: "referred"
  },
  {
    name: "Čakajúci",
    key: "waiting"
  },
  {
    name: "Vyriešený",
    key: "resolved"
  },
  {
    name: "Neriešený",
    key: "unresolved"
  },
  {
    name: "V riešení",
    key: "in_progress"
  },
  {
    name: "Neprijatý",
    key: "rejected"
  },
  {
    name: "Uzavretý",
    key: "closed"
  },
  {
    name: "Označený za vyriešený",
    key: "marked_as_resolved"
  }
].each do |state_data|
  Issues::State.find_or_create_by!(name: state_data[:name]).tap do |issues_state|
    issues_state.update(key: state_data[:key])
  end
end

[
  { triage_external_id: 1, name: "Cesty a chodníky", name_hu: "Közutak és közterület", alias: "cesty-a-dopravne-znacenie", description: "cesty, cyklotrasy, schody, oplotenie", description_hu: "utak, kerékpárutak, lépcsők, kerítések", weight: 1000, legacy_id: 16 },
  { triage_external_id: 2, name: "Zeleň a životné prostredie", name_hu: "Zöldterületek", alias: "priroda-a-zivotne-prostredie", description: "stromy, neporiadok, znečisťovanie", description_hu: "fák, rendetlenség, szennyezés", weight: 900, legacy_id: 1 },
  { triage_external_id: 3, name: "Dopravné značenie", name_hu: "Közúti jelzések", alias: "dopravne-znacenie", description: "značky, semafory, stĺpiky", description_hu: "jelzőtáblák, közlekedési lámpák, pollerek", weight: 800, legacy_id: 25 },
  { triage_external_id: 4, name: "Mestský mobiliár", name_hu: "Közterületek berendezései ", alias: "Mestský mobiliár", description: "koše, ihriská, lavičky, zastávky MHD", description_hu: "szemétkosarak, játszóterek, padok, tömegközlekedési megállók", weight: 700, legacy_id: 9 },
  { triage_external_id: 5, name: "Automobily", name_hu: "Gépjármûvek", alias: " Automobily", description: "parkovanie, dlhodobo odstavené vozidlá", description_hu: "parkolás, elhagyott járművek", weight: 600, legacy_id: 184 },
  { triage_external_id: 6, name: "Verejné služby", name_hu: "Közszolgáltatások", alias: "kanalizacia", description: "osvetlenie, kanalizácia, MHD, web, rozvodné siete", description_hu: "közvilágítás, csatornahálózat, városi tömegközlekedés, honlap, közműhálózat", weight: 500, legacy_id: 14 },
  { triage_external_id: 7, name: "Verejný poriadok", name_hu: "Közrend", alias: "verejny-poriadok", description: "stavby, reklama, vandalizmus", description_hu: "építkezések, reklámok, vandalizmus", weight: 400, legacy_id: 21 }
].each do |category|
  cat = Issues::Category.find_or_initialize_by(
    name: category[:name],
    name_hu: category[:name_hu],
    alias: category[:alias],
    description: category[:description],
    description_hu: category[:description_hu],
    weight: category[:weight],
    legacy_id: category[:legacy_id]
  ).tap do |c|
    c.triage_external_id = category[:triage_external_id]
  end

  cat.save!
end

cms_root = Cms::Category.find_or_create_by!(
  id: ENV["CMS_ROOT_CATEGORY_ID"],
  slug: "cms",
) do |category|
  category.name = "CMS"
end

cms_novinky = Cms::Category.find_or_create_by!(
  slug: "aktuality",
  parent_category_id: cms_root.id,
) do |category|
  category.name = "Aktuality"
end

def generate_fake_pages(category)
  Cms::Page.find_or_create_by!(
    slug: "o-nas",
    category_id: category.id
  ) do |page|
    page.title = "O nás"
    page.text = 5.times.map { Faker::Lorem.paragraph_by_chars }.map { |par| "<p>#{par}</p>" }.join("\n")
    page.raw = ""
    page.tags = [ "published" ]

    page.created_at = DateTime.now - 7.days
    page.updated_at = DateTime.now - 7.days
  end

  Cms::Page.find_or_create_by!(
    slug: "kontakt",
    category_id: category.id
  ) do |page|
    page.title = "Kontakt"
    page.text = 5.times.map { Faker::Lorem.paragraph_by_chars }.map { |par| "<p>#{par}</p>" }.join("\n")
    page.raw = ""
    page.tags = [ "published" ]

    page.created_at = DateTime.now - 7.days
    page.updated_at = DateTime.now - 7.days
  end
end

def generate_fake_announcements(category)
  25.times do |n|
    title = Faker::Lorem.sentence

    Cms::Page.find_or_create_by!(id: n + 1000, category_id: category.id) do |page|
      page.title = title
      page.slug = title.parameterize
      page.text = 5.times.map { Faker::Lorem.paragraph_by_chars }.map { |par| "<p>#{par}</p>" }.join("\n")
      page.raw = ""
      page.tags = [ "published" ]

      page.created_at = DateTime.now - (40 - n).day
      page.updated_at = DateTime.now - (40 - n).day
    end
  end

  Cms::Page.find_or_create_by!(
    slug: "new-portal",
    category_id: category.id
  ) do |page|
    page.title = "New Portal!"
    page.text = "<p><strong>Lorem Ipsum</strong> is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.</p>" * 4
    page.raw = ""
    page.tags = [ "published" ]

    page.created_at = DateTime.now - 7.days
    page.updated_at = DateTime.now - 7.days
  end

  Cms::Page.find_or_create_by!(
    slug: "community-guidelines",
    category_id: category.id
  ) do |page|
    page.title = "Updated Community Guidelines"
    page.text = "<p>We’ve updated our community guidelines to ensure a safer environment for all.</p>" * 4
    page.raw = ""
    page.tags = []

    page.created_at = DateTime.now - 6.days
    page.updated_at = DateTime.now - 6.days
  end

  Cms::Page.find_or_create_by!(
    slug: "dark-mode",
    category_id: category.id
  ) do |page|
    page.title = "Dark Mode is Here!"
    page.text = "<p><strong>Great news!</strong> Dark Mode has been added to improve your experience and reduce eye strain. You can enable it in your settings and enjoy a sleeker, more comfortable interface.</p>" * 4
    page.raw = ""
    page.tags = [ "published" ]

    page.created_at = DateTime.now - 5.days
    page.updated_at = DateTime.now - 5.days
  end

  Cms::Page.find_or_create_by!(
    slug: "holiday-hours",
    category_id: category.id
  ) do |page|
    page.title = "Holiday Hours Notice"
    page.text = "<p>Check out our adjusted operating hours for the upcoming holiday season.</p>" * 4
    page.raw = ""
    page.tags = [ "published" ]

    page.created_at = DateTime.now - 4.days
    page.updated_at = DateTime.now - 4.days
  end

  Cms::Page.find_or_create_by!(
    slug: "system-maintenance",
    category_id: category.id
  ) do |page|
    page.title = "System Maintenance Scheduled"
    page.text = "<p><strong>Attention!</strong> Our team will conduct routine maintenance to enhance security and performance. During this time, some services may be temporarily unavailable. We apologize for any inconvenience and appreciate your patience.</p>" * 4
    page.raw = ""
    page.tags = []

    page.created_at = DateTime.now - 3.days
    page.updated_at = DateTime.now - 3.days
  end

  Cms::Page.find_or_create_by!(
    slug: "mobile-app-release",
    category_id: category.id
  ) do |page|
    page.title = "Our Mobile App is Live!"
    page.text = "<p><strong>Great news!</strong> Our brand-new mobile app is now available for download on iOS and Android. Enjoy a seamless experience with enhanced features, push notifications, and improved performance. Get it today and stay connected on the go!</p>" * 4
    page.raw = ""
    page.tags = [ "published" ]

    page.created_at = DateTime.now - 2.days
    page.updated_at = DateTime.now - 2.days
  end

  Cms::Page.find_or_create_by!(
    slug: "dashboard-upgrade",
    category_id: category.id
  ) do |page|
    page.title = "New and Improved User Dashboard!"
    page.text = "<p><strong>Exciting updates!</strong> Your user dashboard just got a major upgrade. We’ve improved navigation, added new analytics tools, and enhanced performance to make your experience smoother and more efficient. Log in now to explore the new design!</p>" * 4
    page.raw = ""
    page.tags = []

    page.created_at = DateTime.now - 1.days
    page.updated_at = DateTime.now - 1.days
  end
end

# uncomment to generate
generate_fake_pages(cms_root)
generate_fake_announcements(cms_novinky)
