require "test_helper"

class MunicipalityBoundaryTest < ActiveSupport::TestCase
  test "bounds are the south-west and north-east corners of the boundary" do
    bounds = MunicipalityBoundary.with_bounds.find(municipality_boundaries(:bratislava).id).bounds

    assert_in_delta 48.0347, bounds[0][0]
    assert_in_delta 17.0098, bounds[0][1]
    assert_in_delta 48.2347, bounds[1][0]
    assert_in_delta 17.2098, bounds[1][1]
  end

  test "a municipality boundary is matched by its municipality, a district boundary by its district" do
    assert_predicate municipality_boundaries(:bratislava), :matched?
    assert_not_predicate municipality_boundaries(:unmatched_municipality), :matched?
    assert_predicate municipality_boundaries(:stare_mesto), :matched?
    assert_not_predicate municipality_boundaries(:bratislava_unmatched_district), :matched?
  end

  test "map features carry the names and flags shown on the map and the outline as GeoJSON" do
    boundary = municipality_boundaries(:stare_mesto)

    feature = MunicipalityBoundary.where(id: boundary.id).map_features(zoom: 12).sole

    assert_equal "district", feature.boundary_kind
    assert_equal "Bratislava", feature.municipality_name
    assert_equal true, feature.municipality_active
    assert_equal "Staré Mesto", feature.municipality_district_name
    assert_predicate feature, :matched?
    assert_equal "Polygon", JSON.parse(feature.geojson)["type"]
  end

  test "map features are simplified more when zoomed out" do
    boundary = municipality_boundaries(:unmatched_municipality)

    points = ->(zoom) { JSON.parse(MunicipalityBoundary.where(id: boundary.id).map_features(zoom: zoom).sole.geojson)["coordinates"].first.size }

    assert_equal 6, points.call(19)
    assert_equal 5, points.call(5)
  end
end
