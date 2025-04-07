class Cms::ImportCategoryJob < ApplicationJob
  def perform(category_id, discourse_client: DiscourseApiClient.new, import_category_pages_job: Cms::ImportCategoryPagesJob)
    all_categories_raw = discourse_client.load_root_categories_with_children

    root_category_raw = find_root_category(all_categories_raw, category_id)

    if root_category_raw
      # category_id is a root category, we are importing whole subtree
      root_category = upsert_category(root_category_raw)

      child_categories = root_category_raw["subcategory_list"].to_a.map do |child_raw|
        upsert_category(child_raw, parent_category_id: root_category.id)
      end

      [ root_category, child_categories ].flatten.each do |category|
        import_category_pages_job.perform_later(category)
      end

      return
    end

    root_category_raw, child_category_raw = find_child_category(all_categories_raw, category_id)

    if root_category_raw
      # category_id is a child category, we are importing only child category and its parent
      root_category = upsert_category(root_category_raw)
      child_category = upsert_category(child_category_raw, parent_category_id: root_category.id)

      import_category_pages_job.perform_later(child_category)
    end
  end

  private

  def find_root_category(raw_categories, category_id)
    raw_categories.find { |root_raw| root_raw["id"] == category_id.to_i }
  end

  def find_child_category(raw_categories, category_id)
    root_category_raw = raw_categories.find do |root_raw|
      root_raw["subcategory_list"].to_a.find { |child_raw| child_raw["id"] == category_id.to_i }
    end

    return nil if root_category_raw.nil?

    child_category_raw = root_category_raw["subcategory_list"].to_a.find { |child_raw| child_raw["id"] == category_id.to_i }

    [ root_category_raw, child_category_raw ]
  end

  def upsert_category(category_raw, parent_category_id: nil)
    Cms::Category.find_or_initialize_by(id: category_raw["id"]).tap do |category|
      category.assign_attributes(
        name: category_raw["name"],
        slug: category_raw["slug"],
        raw: category_raw,
        parent_category_id: parent_category_id
      )
      category.save!
    end
  end
end
