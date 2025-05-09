c = Cms::Category.find_or_create_by!(id: ENV['CMS_AI_CATEGORY_ID']) do |c|
  c.name = 'AI'
  c.slug = 'ai'
end

c.pages.find_or_initialize_by(tags: "{prompt:generatechecks}").tap do |page|
  page.title = "Generate Checks"
  page.slug = "generate-checks"
  page.text = "-"
  page.raw = File.read(Rails.root + 'db/seeds/fixtures/ai_prompt_generatechecks.md')
end.save!

c.pages.find_or_initialize_by(tags: "{prompt:generatesuggestions}").tap do |page|
  page.title = "Generate Suggestions"
  page.slug = "generate-suggestions"
  page.text = "-"
  page.raw = File.read(Rails.root + 'db/seeds/fixtures/ai_prompt_generatesuggestions.md')
end.save!
