File.read(Rails.root + 'db/seeds/fixtures/ai_prompt_generatesuggestions.md').each_line do |line|
  next unless line =~ /\| (.+) \| (.+) \| (.+) \|/
  next if $1 == 'category'
  next if $1[0] == '-'
  cat_name = $1
  sub_name = $2
  type_name = $3
  type_name = nil if type_name == '-'

  category = Issues::Category.find_or_create_by!(name: cat_name, legacy_id: nil)
  subcat = category.subcategories.find_or_create_by!(name: sub_name, category_id: category.id, legacy_id: nil)
  if type_name
    subcat.subtypes.find_or_create_by!(name: type_name, subcategory_id: subcat.id, legacy_id: nil)
  end
end
