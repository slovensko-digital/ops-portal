class DiscourseApiClient
  attr_reader :client

  def initialize(url: ENV["DISCOURSE_URL"], api_key: ENV["DISCOURSE_API_KEY"], api_username: ENV["DISCOURSE_API_USERNAME"])
    @client = DiscourseApi::Client.new(url, api_key, api_username)
  end

  def load_root_categories_with_children
    @client.categories({ "include_subcategories" => true })
  end

  def load_all_topic_ids_for_root_category(category_slug)
    load_all_topics do |page|
      # /none to avoid loading sub category topics
      @client.category_latest_topics_full({ category_slug: "#{category_slug}/none", page: page })
    end
  end

  def load_all_topic_ids_for_sub_category(category_slug)
    load_all_topics { |page| @client.category_latest_topics_full({ category_slug: category_slug, page: page }) }
  end

  def load_topic(topic_id)
    client.topic(topic_id)
  end

  private

  def load_all_topics
    page = 0
    topics = []

    begin
      result = yield page
      topics << result["topic_list"]["topics"].map { |topic| topic["id"] }
      page += 1
    end while result["topic_list"]["more_topics_url"].present?

    topics.flatten
  end
end
