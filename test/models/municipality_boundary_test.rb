require "test_helper"

class MunicipalityBoundaryTest < ActiveSupport::TestCase
  test "bounds are the south-west and north-east corners of the boundary" do
    boundary = create_municipality_boundary(municipality: municipalities(:bratislava), center_lat: 48.15, center_lon: 17.1)

    bounds = MunicipalityBoundary.with_bounds.find(boundary.id).bounds

    assert_in_delta 48.05, bounds[0][0]
    assert_in_delta 17.0, bounds[0][1]
    assert_in_delta 48.25, bounds[1][0]
    assert_in_delta 17.2, bounds[1][1]
  end

  test "a municipality boundary is matched by its municipality, a district boundary by its district" do
    bratislava = municipalities(:bratislava)

    assert_predicate MunicipalityBoundary.new(boundary_kind: "municipality", municipality: bratislava), :matched?
    assert_not_predicate MunicipalityBoundary.new(boundary_kind: "municipality"), :matched?
    assert_predicate MunicipalityBoundary.new(boundary_kind: "district", municipality_district: municipality_districts(:stare_mesto_ba)), :matched?
    assert_not_predicate MunicipalityBoundary.new(boundary_kind: "district", municipality: bratislava), :matched?
  end
end
