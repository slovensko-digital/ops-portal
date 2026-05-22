require "test_helper"

class MunicipalityTest < ActiveSupport::TestCase
  test "find_by_address returns municipality by municipality when only municipality matches aliases" do
    assert_equal [ municipalities("banska_bystrica"), nil ], Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "banska-bystrica",
      suburb: "Irrelevant"
    )
  end

  test "find_by_address returns municipality district when suburb matches district aliases" do
    municipality = municipalities("bratislava")
    district = municipality_districts("stare_mesto_ba")

    assert_equal [ municipality, district ], Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "Bratislava",
      suburb: "stare-mesto"
    )
  end

  test "find_by_address prioritizes district from Bratislava when multiple districts match" do
    municipality = municipalities("bratislava")
    district = municipality_districts("stare_mesto_ba")

    assert_equal [ municipality, district ], Municipality.find_by_address(
      city: "Bratislava",
      municipality: "Staré Mesto",
      suburb: "Irrelevant"
    )
  end

  test "find_by_address returns correct municipality district for Bratislava Rusovce" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Rusovce")

    assert_equal [ municipality, district ], Municipality.find_by_address(
      city: "Bratislava",
      municipality: nil,
      suburb: "Rusovce"
    )
  end

  test "find_by_address returns correct municipality district for Bratislava Podunajské Biskupice" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Podunajské Biskupice")
    assert_equal [ municipality, district ], Municipality.find_by_address(
      city: "Bratislava",
      municipality: nil,
      suburb: "Podunajské Biskupice"
    )
  end

  test "find_by_address returns only municipality district when municipality district in Bratislava is not active" do
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    assert_equal [ nil, district ], Municipality.find_by_address(
      city: "Bratislava",
      municipality: nil,
      suburb: "Ružinov"
    )
  end

  test "find_by_address returns nil when municipality exists but has no aliases" do
    municipality = municipalities("bratislava")
    municipality.update!(aliases: [])

    assert_equal [ nil, nil ], Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "Bratislava",
      suburb: "Irrelevant"
    )
  end

  test "find_by_address returns nil, nil when municipality exists but is not active" do
    municipality = municipalities("banska_bystrica")
    municipality.update!(active: false)

    assert_equal [ nil, nil ], Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "banska-bystrica",
      suburb: "Irrelevant"
    )
  end

  test "find_by_address returns correct municipality district when whitelisted street is provided" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    municipality.streets.create(name: "Cesta mládeže", whitelisted: true)

    assert_equal [ municipality, district ], Municipality.find_by_address(
      city: "Bratislava",
      municipality: nil,
      suburb: "Ružinov",
      street: "Cesta mládeže"
    )
  end

  test "find_by_address returns nil, district when street is not whitelisted" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    municipality.streets.create(name: "Búdková", whitelisted: false)

    assert_equal [ nil, district ], Municipality.find_by_address(
      city: "Bratislava",
      municipality: nil,
      suburb: "Ružinov",
      street: "Cesta mládeže"
    )
  end

  test "find_by_coordinates returns nil when latitude or longitude is blank" do
    assert_equal [ nil, nil ], Municipality.find_by_coordinates(nil, 17.0)
    assert_equal [ nil, nil ], Municipality.find_by_coordinates(48.0, nil)
  end

  test "find_by_coordinates returns municipality when point is inside municipality boundary" do
    municipality = municipalities("banska_bystrica")
    create_municipality_boundary(municipality: municipality, center_lat: municipality.latitude, center_lon: municipality.longitude)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ municipality, nil ], [ m, d ]
  end

  test "find_by_coordinates returns municipality district when point is inside district boundary" do
    municipality = municipalities("bratislava")
    district = municipality_districts("stare_mesto_ba")
    create_municipality_boundary(municipality: municipality, district: district, center_lat: municipality.latitude, center_lon: municipality.longitude)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ municipality, district ], [ m, d ]
  end

  test "find_by_coordinates returns nil when municipality is inactive" do
    municipality = municipalities("banska_bystrica")
    municipality.update!(active: false)
    create_municipality_boundary(municipality: municipality, center_lat: municipality.latitude, center_lon: municipality.longitude)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ nil, nil ], [ m, d ]
  end

  test "find_by_coordinates returns nil, district when district is inactive" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    create_municipality_boundary(municipality: municipality, district: district, center_lat: municipality.latitude, center_lon: municipality.longitude)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude)
    assert_equal [ nil, district ], [ m, d ]
  end

  test "find_by_coordinates returns municipality district when whitelisted street is provided for inactive district" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    municipality.streets.create(name: "Cesta mládeže", whitelisted: true)
    create_municipality_boundary(municipality: municipality, district: district, center_lat: municipality.latitude, center_lon: municipality.longitude)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude, street: "Cesta mládeže")
    assert_equal [ municipality, district ], [ m, d ]
  end

  test "find_by_coordinates returns nil, district when street is not whitelisted for inactive district" do
    municipality = municipalities("bratislava")
    district = municipality_districts("Ružinov")
    district.update!(active: false)
    municipality.streets.create(name: "Búdková", whitelisted: false)
    create_municipality_boundary(municipality: municipality, district: district, center_lat: municipality.latitude, center_lon: municipality.longitude)

    m, d = Municipality.find_by_coordinates(municipality.latitude, municipality.longitude, street: "Cesta mládeže")
    assert_equal [ nil, district ], [ m, d ]
  end

  test "find_by_coordinates returns nil when point is outside all boundaries" do
    m, d = Municipality.find_by_coordinates(0.0, 0.0)
    assert_equal [ nil, nil ], [ m, d ]
  end
end
