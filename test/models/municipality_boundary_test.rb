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

  test "map features carry the names and flags shown on the map and the outline as GeoJSON" do
    bratislava = municipalities(:bratislava)
    bratislava.update!(active: true)
    stare_mesto = municipality_districts(:stare_mesto_ba)
    boundary = create_municipality_boundary(municipality: bratislava, district: stare_mesto, center_lat: 48.15, center_lon: 17.1)

    feature = MunicipalityBoundary.where(id: boundary.id).map_features(zoom: 12).sole

    assert_equal "district", feature.boundary_kind
    assert_equal "Bratislava", feature.municipality_name
    assert_equal true, feature.municipality_active
    assert_equal stare_mesto.name, feature.municipality_district_name
    assert_predicate feature, :matched?
    assert_equal "Polygon", JSON.parse(feature.geojson)["type"]
  end

  test "map features are simplified more when zoomed out" do
    detailed = create_municipality_boundary_with_wkt("POLYGON((17 48, 17.0001 48.05, 17 48.1, 17.1 48.1, 17.1 48, 17 48))")

    points = ->(zoom) { JSON.parse(MunicipalityBoundary.where(id: detailed.id).map_features(zoom: zoom).sole.geojson)["coordinates"].first.size }

    assert_equal 6, points.call(19)
    assert_equal 5, points.call(5)
  end

  private

  def create_municipality_boundary_with_wkt(wkt)
    ActiveRecord::Base.connection.execute(ActiveRecord::Base.sanitize_sql([ <<~SQL, wkt ]))
      INSERT INTO municipality_boundaries (boundary_kind, boundary, created_at, updated_at)
      VALUES ('municipality', ST_SetSRID(ST_GeomFromText(?), 4326), NOW(), NOW())
    SQL
    MunicipalityBoundary.order(:id).last
  end
end
