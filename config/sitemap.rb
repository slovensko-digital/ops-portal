require "aws-sdk-s3"

SitemapGenerator::Sitemap.default_host = "https://novy.odkazprestarostu.sk/"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

sitemap_config = Rails.application.config_for(:sitemap)
SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  sitemap_config[:bucket],
  acl: nil,
  access_key_id: sitemap_config[:access_key_id],
  secret_access_key: sitemap_config[:secret_access_key],
  region: sitemap_config[:region],
  endpoint: sitemap_config[:endpoint]
)

SitemapGenerator::Sitemap.create do
  add root_path, changefreq: "daily", priority: 1.0

  add "/aktuality", changefreq: "weekly", priority: 0.8

  add new_issues_draft_path, changefreq: "monthly", priority: 0.9

  Issue.searchable.with_attached_photos.find_each do |issue|
    images = []
    if issue.photos.attached?
      issue.photos.each do |photo|
        images << {
          loc: Rails.application.routes.url_helpers.rails_blob_url(photo, host: SitemapGenerator::Sitemap.default_host),
          title: issue.title
        }
      end
    end

    add issue_path(issue),
        lastmod: issue.updated_at,
        changefreq: "weekly",
        priority: 0.8,
        images: images
  end

  root_category_id = ENV["CMS_ROOT_CATEGORY_ID"].to_i
  Cms::Page.published.includes(:category).find_each do |page|
    if page.category_id == root_category_id
      path = page.slug
    else
      path = "#{page.category.slug}/#{page.slug}"
    end

    add path, lastmod: page.updated_at, priority: 0.7
  end

  Municipality.active.where(active_on_old_portal: false).find_each do |municipality|
    add issues_path(obec: municipality.name),
        changefreq: "daily",
        priority: 0.6
  end
end
