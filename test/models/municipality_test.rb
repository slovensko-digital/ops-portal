require "test_helper"

class MunicipalityTest < ActiveSupport::TestCase
  test "find_by_address returns municipality by municipality when only municipality matches aliases" do
    municipality = municipalities(:two)

    result_municipality, result_district = Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "banska-bystrica",
      suburb: "Irrelevant"
    )

    assert_equal municipality, result_municipality
    assert_nil result_district
  end

  test "find_by_address returns municipality district when suburb matches district aliases" do
    municipality = municipalities(:one)
    district = municipality_districts(:one)

    result_municipality, result_district = Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "Bratislava",
      suburb: "stare-mesto"
    )

    assert_equal municipality, result_municipality
    assert_equal district, result_district
  end

  test "find_by_address prioritizes district from Bratislava when multiple districts match" do
    bratislava = municipalities(:one)
    district = municipality_districts(:one)

    result_municipality, result_district = Municipality.find_by_address(
      city: "Bratislava",
      municipality: "Staré Mesto",
      suburb: "Irrelevant"
    )

    assert_equal bratislava, result_municipality
    assert_equal district, result_district
  end

  test "find_by_address returns nil when municipality exists but has no aliases" do
    municipality = municipalities(:one)
    municipality.update!(aliases: [])

    result_municipality, result_district = Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "Bratislava",
      suburb: "Irrelevant"
    )

    assert_nil result_municipality
    assert_nil result_district
  end

  test "find_by_address returns nil, nil when municipality exists but is not active" do
    municipality = municipalities(:two)
    municipality.update!(active: false)

    result_municipality, result_district = Municipality.find_by_address(
      city: "Irrelevant",
      municipality: "banska-bystrica",
      suburb: "Irrelevant"
    )

    assert_nil result_municipality
    assert_nil result_district
  end
end
