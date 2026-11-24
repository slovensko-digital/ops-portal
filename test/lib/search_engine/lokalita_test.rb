require "test_helper"

class SearchEngine::LokalitaTest < ActiveSupport::TestCase
  test "joins a municipality and a district with a hyphen" do
    assert_equal "Bratislava-Petržalka", SearchEngine::Lokalita.value("Bratislava", "Petržalka")
    assert_equal "Bratislava", SearchEngine::Lokalita.value("Bratislava")
  end

  test "resolves municipalities and districts" do
    lokalita = SearchEngine::Lokalita.new([ "Nitra", "Bratislava-Petržalka" ])

    assert_equal [ "Nitra" ], lokalita.municipalities.map(&:name)
    assert_equal [ municipality_districts(:Petržalka) ], lokalita.districts
    assert_equal "Petržalka", lokalita.label("Bratislava-Petržalka")
    assert_equal "Nitra", lokalita.label("Nitra")
  end

  test "a municipality with a hyphen in its name stays a municipality" do
    lokalita = SearchEngine::Lokalita.new([ "Súľov-Hradná" ])

    assert_equal [ "Súľov-Hradná" ], lokalita.municipalities.map(&:name)
    assert_empty lokalita.districts
    assert_equal "Súľov-Hradná", lokalita.label("Súľov-Hradná")
  end

  test "a district with a hyphen in its name is matched" do
    lokalita = SearchEngine::Lokalita.new([ "Trenčín-Trenčín - Juh" ])

    assert_equal [ "Trenčín - Juh" ], lokalita.districts.map(&:name)
    assert_equal "Trenčín - Juh", lokalita.label("Trenčín-Trenčín - Juh")
  end
end
