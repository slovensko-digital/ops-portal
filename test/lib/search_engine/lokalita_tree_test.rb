require "test_helper"

class SearchEngine::LokalitaTreeTest < ActiveSupport::TestCase
  test "builds parent and district items for every municipality" do
    items = SearchEngine::LokalitaTree.new([]).items

    bratislava = items.find { _1[:value] == "Bratislava" }
    assert_equal "Bratislava", bratislava[:label]
    assert_equal 0, bratislava[:level]
    assert_not bratislava[:selected]
    assert_equal [ "Bratislava" ], bratislava[:add_params]
    assert_equal [], bratislava[:remove_params]

    petrzalka = items.find { _1[:value] == "Bratislava - Petržalka" }
    assert_equal "Petržalka", petrzalka[:label]
    assert_equal 1, petrzalka[:level]
    assert_not petrzalka[:selected]
    assert_equal [ "Bratislava - Petržalka" ], petrzalka[:add_params]
    assert_equal [], petrzalka[:remove_params]
  end

  test "marks selected locations and toggles districts and exclusions" do
    items = SearchEngine::LokalitaTree.new([ "Nitra", "Bratislava - Petržalka", "-Bratislava - Ružinov" ]).items

    nitra = items.find { _1[:value] == "Nitra" }
    assert nitra[:selected]
    assert_equal [ "Bratislava - Petržalka", "-Bratislava - Ružinov", "Nitra" ], nitra[:add_params]
    assert_equal [ "Bratislava - Petržalka", "-Bratislava - Ružinov" ], nitra[:remove_params]

    petrzalka = items.find { _1[:value] == "Bratislava - Petržalka" }
    assert petrzalka[:selected]
    assert_equal [ "Nitra", "-Bratislava - Ružinov" ], petrzalka[:remove_params]

    ruzinov = items.find { _1[:value] == "Bratislava - Ružinov" }
    assert_not ruzinov[:selected]
    assert_equal [ "Nitra", "Bratislava - Petržalka", "-Bratislava - Ružinov", "Bratislava - Ružinov" ],
      ruzinov[:add_params]
  end
end
