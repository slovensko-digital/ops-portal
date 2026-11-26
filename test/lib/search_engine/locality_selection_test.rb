require "test_helper"

class SearchEngine::LocalitySelectionTest < ActiveSupport::TestCase
  test "joins a municipality and a district with a hyphen" do
    assert_equal "Bratislava-Petržalka", SearchEngine::LocalitySelection.param(municipality_districts(:Petržalka))
    assert_equal "Bratislava", SearchEngine::LocalitySelection.param(municipalities(:bratislava))
    assert_equal "Bratislava-Petržalka", SearchEngine::LocalitySelection.param_from_names("Bratislava", "Petržalka")
    assert_equal "Bratislava", SearchEngine::LocalitySelection.param_from_names("Bratislava")
  end

  test "passes a value through" do
    assert_equal "Nitra", SearchEngine::LocalitySelection.param("Nitra")
  end

  test "resolves municipalities and districts" do
    localities = SearchEngine::LocalitySelection.new([ "Nitra", "Bratislava-Petržalka" ])

    assert_equal [ "Nitra" ], localities.municipalities.map(&:name)
    assert_equal [ municipality_districts(:Petržalka) ], localities.districts
    assert_equal "Petržalka", localities.label("Bratislava-Petržalka")
    assert_equal "Nitra", localities.label("Nitra")
  end

  test "a municipality with a hyphen in its name stays a municipality" do
    localities = SearchEngine::LocalitySelection.new([ "Súľov-Hradná" ])

    assert_equal [ "Súľov-Hradná" ], localities.municipalities.map(&:name)
    assert_empty localities.districts
    assert_equal "Súľov-Hradná", localities.label("Súľov-Hradná")
  end

  test "a district with a hyphen in its name is matched" do
    localities = SearchEngine::LocalitySelection.new([ "Trenčín-Trenčín - Juh" ])

    assert_equal [ "Trenčín - Juh" ], localities.districts.map(&:name)
    assert_equal "Trenčín - Juh", localities.label("Trenčín-Trenčín - Juh")
  end

  test "ignores values that are not strings" do
    localities = SearchEngine::LocalitySelection.new([ 1, nil, "  ", "Nitra" ])

    assert_equal [ "Nitra" ], localities.municipalities.map(&:name)
    assert_empty localities.districts
  end
end
