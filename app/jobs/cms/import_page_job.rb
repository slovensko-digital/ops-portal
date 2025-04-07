class Cms::ImportPageJob < ApplicationJob
  def perform(topic_id, discourse_client: DiscourseApiClient.new)
    topic_result = discourse_client.load_topic(topic_id)

    page = Cms::Page.find_by(id: topic_result["id"])
    if topic_result["deleted_at"]
      page.destroy! if page

      return
    end

    # category exists, everything is ok
    category = Cms::Category.find_by(id: topic_result["category_id"])
    if category
      upsert_page(topic_result, category)
    else
      page.destroy! if page # if the page was moved to the not existing category, we consider it as deleted
    end
  end

  private

  def upsert_page(topic_raw, category)
    Cms::Page.find_or_initialize_by(id: topic_raw["id"]).tap do |page|
      page.assign_attributes(
        title: topic_raw["title"],
        slug: topic_raw["slug"],
        tags: topic_raw["tags"],
        text: topic_raw.dig("post_stream", "posts", 0, "cooked") || "",
        raw: topic_raw,
        category: category
      )
      page.save!
    end
  end
end
