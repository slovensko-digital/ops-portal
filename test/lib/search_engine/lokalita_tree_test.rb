require "test_helper"

class SearchEngine::LokalitaTreeTest < ActiveSupport::TestCase
  setup do
    @bratislava_districts = municipalities(:bratislava).active_districts.map { "Bratislava-#{_1.name}" }
  end

  def item(items, value)
    items.find { _1[:value] == value }
  end

  test "builds parent and district items for every municipality" do
    items = SearchEngine::LokalitaTree.new([]).items

    bratislava = item(items, "Bratislava")
    assert_equal "Bratislava", bratislava[:label]
    assert_equal 0, bratislava[:level]
    assert_not bratislava[:selected]
    assert_not bratislava[:partial]
    assert_equal [ "Bratislava" ], bratislava[:add_params]
    assert_equal [], bratislava[:remove_params]

    petrzalka = item(items, "Bratislava-Petržalka")
    assert_equal "Petržalka", petrzalka[:label]
    assert_equal 1, petrzalka[:level]
    assert_not petrzalka[:selected]
    assert_equal [ "Bratislava-Petržalka" ], petrzalka[:add_params]
    assert_equal [], petrzalka[:remove_params]
  end

  test "a selected municipality shows all its districts as selected" do
    items = SearchEngine::LokalitaTree.new([ "Nitra", "Bratislava" ]).items

    assert item(items, "Bratislava")[:selected]
    assert_not item(items, "Bratislava")[:partial]
    assert item(items, "Bratislava-Petržalka")[:selected]
    assert item(items, "Bratislava-Ružinov")[:selected]
    assert_equal [ "Nitra" ], item(items, "Bratislava")[:remove_params]
  end

  test "unselecting a district of a selected municipality keeps its other districts" do
    items = SearchEngine::LokalitaTree.new([ "Nitra", "Bratislava" ]).items

    remove_params = item(items, "Bratislava-Ružinov")[:remove_params]

    assert_equal [ "Nitra", *(@bratislava_districts - [ "Bratislava-Ružinov" ]) ], remove_params
  end

  test "a municipality with only some districts selected is partial" do
    items = SearchEngine::LokalitaTree.new([ "Bratislava-Petržalka" ]).items

    bratislava = item(items, "Bratislava")
    assert_not bratislava[:selected]
    assert bratislava[:partial]
    assert_equal [ "Bratislava" ], bratislava[:add_params]

    assert item(items, "Bratislava-Petržalka")[:selected]
    assert_not item(items, "Bratislava-Ružinov")[:selected]
    assert_equal [ "Bratislava-Petržalka", "Bratislava-Ružinov" ], item(items, "Bratislava-Ružinov")[:add_params]
  end

  test "selecting the last missing district selects the whole municipality" do
    items = SearchEngine::LokalitaTree.new([ "Nitra", *(@bratislava_districts - [ "Bratislava-Ružinov" ]) ]).items

    assert_equal [ "Nitra", "Bratislava" ], item(items, "Bratislava-Ružinov")[:add_params]
  end
end
