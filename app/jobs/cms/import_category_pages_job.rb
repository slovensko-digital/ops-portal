class Cms::ImportCategoryPagesJob < ApplicationJob
  def perform(category, discourse_client: DiscourseApiClient.new)
    # get all category pages
  end
end
