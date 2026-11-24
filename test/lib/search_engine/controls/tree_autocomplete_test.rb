require "test_helper"

class SearchEngine::Controls::TreeAutocompleteTest < ActiveSupport::TestCase
  def control
    SearchEngine::Controls::TreeAutocomplete.new(
      param_name: :lokalita,
      label: "Obec / Mestská časť",
      items: [],
      filter: ->(scope, _params) { scope },
      filter_label: ->(value) { value.to_s.split(" - ", 2).last }
    )
  end

  def results_with(*lokalita)
    results = SearchEngine::Results.new
    results.search_params = { lokalita: lokalita }.with_indifferent_access
    results
  end

  test "removing a city chip also removes its districts" do
    results = results_with("Nitra", "Bratislava", "Bratislava - Ružinov")
    control.add_applied_filter(results)

    city_chip = results.applied_filters.find { _1.label == "Bratislava" }

    assert_equal [ "Nitra" ], city_chip.remove_filter_params[:lokalita]
  end

  test "removing a district chip keeps the rest of the selection" do
    results = results_with("Nitra", "Bratislava - Petržalka", "Bratislava - Ružinov")
    control.add_applied_filter(results)

    district_chip = results.applied_filters.find { _1.label == "Ružinov" }

    assert_equal [ "Nitra", "Bratislava - Petržalka" ], district_chip.remove_filter_params[:lokalita]
  end
end
