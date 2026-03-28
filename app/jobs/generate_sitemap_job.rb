class GenerateSitemapJob < ApplicationJob
  def perform
    SitemapGenerator::Interpreter.run
    SitemapGenerator::Sitemap.ping_search_engines
  end
end
