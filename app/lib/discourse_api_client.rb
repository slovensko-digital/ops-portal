class DiscourseApiClient
  attr_reader :client

  def initialize(url: ENV["DISCOURSE_URL"], api_key: ENV["DISCOURSE_API_KEY"], api_username: ENV["DISCOURSE_API_USERNAME"])
    @client = DiscourseApi::Client.new(url, api_key, api_username)
  end

  def load_root_categories_with_children
    @client.categories({ "include_subcategories" => true })
  end
end
