class Cms::ImportCategoryPagesJob < ApplicationJob
  def perform(category, discourse_client: DiscourseApiClient.new)
    page_ids_to_delete = category.page_ids.to_set

    topic_ids = load_category_topic_ids(discourse_client, category)

    topic_ids.each do |topic_id|
      topic_result = discourse_client.load_topic(topic_id)
      if topic_result["deleted_at"].nil?
        page = upsert_page(topic_result, category)
        page_ids_to_delete.delete(page.id)
      end
    end

    Cms::Page.where(id: page_ids_to_delete).destroy_all
  end

  private

  def load_category_topic_ids(discourse_client, category)
    if category.parent_category.nil?
      discourse_client.load_all_topic_ids_for_root_category(category.discourse_slug)
    else
      discourse_client.load_all_topic_ids_for_sub_category(category.discourse_slug)
    end
  end

  def upsert_page(topic_raw, category)
    Cms::Page.find_or_initialize_by(id: topic_raw["id"]).tap do |page|
      page.assign_attributes(
        title: topic_raw["title"],
        slug: topic_raw["slug"],
        tags: topic_raw["tags"],
        text: topic_raw.dig("post_stream", "posts", 0, "cooked") || "",
        raw: topic_raw,
        category_id: category.id # topic can be moved from other category
      )
      page.save!
    end
  end
end
