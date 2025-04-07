class Cms::ImportCategoryPagesJob < ApplicationJob
  def perform(category, discourse_client: DiscourseApiClient.new, import_page_job: Cms::ImportPageJob)
    page_ids_to_delete = category.page_ids.to_set

    topic_ids = load_category_topic_ids(discourse_client, category)

    topic_ids.each do |topic_id|
      import_page_job.perform_later(topic_id)
      page_ids_to_delete.delete(topic_id)
    end

    # delete pages that are no longer in the category
    Cms::Page.where(id: page_ids_to_delete).destroy_all
  end

  private

  def load_category_topic_ids(discourse_client, category)
    if category.parent_category.nil?
      discourse_client.load_all_topic_ids_for_root_category("#{category.slug}/#{category.id}")
    else
      discourse_client.load_all_topic_ids_for_sub_category("#{category.parent_category.slug}/#{category.slug}/#{category.id}")
    end
  end
end
