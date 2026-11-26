# Searchable dropdowns: the profile's preferred localities and the /dopyty filters
# "Obec / Mestská časť" and "Zodpovedný subjekt".
module SearchSelectHelper
  # Types into the field with the given label and clicks the option with that
  # exact text in the field's own list. Pass search: when the option is found by
  # other text, e.g. a district by its municipality name.
  def select_from_search(option, from:, search: option)
    field = find_field(from)
    field.fill_in(with: search)

    within(field.ancestor(".autocomplete-wrapper")) do
      find("li", exact_text: option).find("label, a").click
    end
  end
end
