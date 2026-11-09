require "test_helper"

class SearchEngine::Controls::TreeAutocompleteTest < ActiveSupport::TestCase
  def control
    SearchEngine::Controls::TreeAutocomplete.new(
      param_name: :lokalita,
      label: "Obec / Mestská časť",
      items: [],
      filter: ->(scope, _params) { scope },
      filter_label: ->(value) do
        if value.to_s.start_with?("-")
          "Okrem: #{value.to_s.delete_prefix("-")}"
        else
          value.to_s.split(" - ", 2).last
        end
      end
    )
  end

  def results_with(*lokalita)
    results = SearchEngine::Results.new
    results.search_params = { lokalita: lokalita }.with_indifferent_access
    results
  end

  test "removing a city chip also removes its exclusions" do
    results = results_with("Bratislava", "-Bratislava - Ružinov")
    control.add_applied_filter(results)

    city_chip = results.applied_filters.find { _1.label == "Bratislava" }

    assert_equal [], city_chip.remove_filter_params[:lokalita]
  end

  test "removing an exclusion chip keeps the rest of the selection" do
    results = results_with("Bratislava", "-Bratislava - Ružinov")
    control.add_applied_filter(results)

    exclusion_chip = results.applied_filters.find { _1.label == "Okrem: Bratislava - Ružinov" }

    assert_equal [ "Bratislava" ], exclusion_chip.remove_filter_params[:lokalita]
  end
end
