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

generate_fake_pages(cms_root)
generate_fake_announcements(cms_novinky)
