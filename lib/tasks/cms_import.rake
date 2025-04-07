namespace :cms do
  desc "Schedules initial import from CMS categories and pages"
  task import: :environment do
    Cms::InitialImportJob.perform_later
  end
end
