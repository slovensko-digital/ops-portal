require "test_helper"

class MunicipalityTest < ActiveSupport::TestCase
  # inside the ruzinov municipality boundary fixture
  RUZINOV_POINT = [ 48.155, 17.165 ].freeze

  test "find_by_coordinates returns nil when latitude or longitude is blank" do
    assert_equal [ nil, nil ], Municipality.find_by_coordinates(nil, 17.0)
    assert_equal [ nil, nil ], Municipality.find_by_coordinates(48.0, nil)
  end

  test "find_by_coordinates returns municipality when point is inside municipality boundary" do
    municipality = municipalities("banska_bystrica")

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ municipality, nil ], [ m, d ]
  end

  test "find_by_coordinates returns municipality district when point is inside district boundary" do
    municipality = municipalities("bratislava")
    district = municipality_districts("stare_mesto_ba")

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ municipality, district ], [ m, d ]
  end

  test "find_by_coordinates returns nil when municipality is inactive" do
    municipality = municipalities("banska_bystrica")
    municipality.update!(active: false)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ nil, nil ], [ m, d ]
  end

  test "find_by_coordinates returns nil, district when district is inactive" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)

    m, d = Municipality.find_by_coordinates(*RUZINOV_POINT)
    assert_equal [ nil, district ], [ m, d ]
  end

  test "find_by_coordinates returns municipality district when whitelisted street is provided for inactive district" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    municipality.streets.create(name: "Cesta mládeže", whitelisted: true)

    m, d = Municipality.find_by_coordinates(*RUZINOV_POINT, street: "Cesta mládeže")
    assert_equal [ municipality, district ], [ m, d ]
  end

  test "find_by_coordinates returns nil, district when street is not whitelisted for inactive district" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    municipality.streets.create(name: "Búdková", whitelisted: false)

    m, d = Municipality.find_by_coordinates(*RUZINOV_POINT, street: "Cesta mládeže")
    assert_equal [ nil, district ], [ m, d ]
  end

  test "find_by_coordinates returns nil when point is outside all boundaries" do
    m, d = Municipality.find_by_coordinates(0.0, 0.0)
    assert_equal [ nil, nil ], [ m, d ]
  end
end
