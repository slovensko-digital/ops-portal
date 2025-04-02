class Cms::InitialImportJob < ApplicationJob
  def perform(category_ids: ENV["DISCOURSE_IMPORT_CATEGORY_IDS"], category_import_job: Cms::ImportCategoryJob)
    category_ids.split(",").each do |id|
      category_import_job.perform_later(id.to_i)
    end
  end
end
