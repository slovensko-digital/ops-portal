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
end
