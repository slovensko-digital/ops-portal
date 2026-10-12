require "test_helper"

class Admin::MunicipalityBoundariesControllerTest < ActionDispatch::IntegrationTest
  include MunicipalityBoundaryTestHelper

  setup do
    @admin = users(:one)
    @original_admin_emails = ENV["ADMIN_EMAILS"]
    ENV["ADMIN_EMAILS"] = @admin.email

    @bratislava = municipalities(:bratislava)
    @stare_mesto = municipality_districts(:stare_mesto_ba)
    @bbox = "16.9,48.0,17.3,48.3"
  end

  teardown do
    ENV["ADMIN_EMAILS"] = @original_admin_emails
  end

  test "returns municipality boundaries in the bbox as GeoJSON" do
    boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: @bratislava, district: @stare_mesto, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: municipalities(:trencin), center_lat: 48.9, center_lon: 18.04)
    login(@admin)

    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 10, bbox: @bbox }

    assert_response :success
    body = response.parsed_body
    assert_equal "FeatureCollection", body["type"]
    assert_equal 1, body["features"].size

    feature = body["features"].first
    assert_equal "Polygon", feature.dig("geometry", "type")
    assert_kind_of Array, feature.dig("geometry", "coordinates")
    assert_equal({
      "id" => boundary.id,
      "kind" => "municipality",
      "municipality_id" => @bratislava.id,
      "municipality_name" => "Bratislava",
      "municipality_active" => true,
      "municipality_district_id" => nil,
      "municipality_district_name" => nil,
      "matched" => true
    }, feature["properties"])
  end

  test "returns district boundaries and flags unmatched ones" do
    create_municipality_boundary(municipality: @bratislava, district: @stare_mesto, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: nil, center_lat: 48.15, center_lon: 17.1, boundary_kind: "district")
    login(@admin)

    get admin_municipality_boundaries_path(format: :json), params: { kind: "district", z: 12, bbox: @bbox }

    assert_response :success
    properties = response.parsed_body["features"].map { it["properties"] }
    assert_equal [ "district" ], properties.map { it["kind"] }.uniq
    assert_equal [ [ @stare_mesto.name, true ], [ nil, false ] ],
      properties.sort_by { it["id"] }.map { [ it["municipality_district_name"], it["matched"] ] }
  end

  test "filters boundaries by matched status and municipality active flag" do
    trencin = municipalities(:trencin)
    @bratislava.update!(active: true)
    trencin.update!(active: false)
    create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: trencin, center_lat: 48.9, center_lon: 18.04)
    create_municipality_boundary(municipality: nil, center_lat: 48.5, center_lon: 17.5)
    login(@admin)

    bbox = "16.9,48.0,18.3,49.1"
    names = ->(*statuses) do
      get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 8, bbox: bbox, statuses: statuses }
      assert_response :success
      response.parsed_body["features"].map { it.dig("properties", "municipality_name") }
    end

    assert_equal [ "Bratislava" ], names.call("active")
    assert_equal [ trencin.name ], names.call("inactive")
    assert_equal [ nil ], names.call("unmatched")
    assert_equal [ "Bratislava", trencin.name ].sort, names.call("active", "inactive").sort
    assert_equal [ "Bratislava", nil ].sort_by(&:to_s), names.call("active", "unmatched").sort_by(&:to_s)
    assert_equal [ "Bratislava", nil, trencin.name ].sort_by(&:to_s), names.call.sort_by(&:to_s)
  end

  test "filters district boundaries by matched status and the active flag of their municipality" do
    @bratislava.update!(active: false)
    matched = create_municipality_boundary(municipality: @bratislava, district: @stare_mesto, center_lat: 48.15, center_lon: 17.1)
    unmatched = create_municipality_boundary(municipality: nil, center_lat: 48.15, center_lon: 17.1, boundary_kind: "district")
    login(@admin)

    ids = ->(*statuses) do
      get admin_municipality_boundaries_path(format: :json), params: { kind: "district", z: 12, bbox: @bbox, statuses: statuses }
      response.parsed_body["features"].map { it.dig("properties", "id") }
    end

    assert_empty ids.call("active")
    assert_equal [ matched.id ], ids.call("inactive")
    assert_equal [ unmatched.id ], ids.call("unmatched")
  end

  test "returns only selected municipalities regardless of bbox" do
    create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    trencin = municipalities(:trencin)
    create_municipality_boundary(municipality: trencin, center_lat: 48.9, center_lon: 18.04)
    login(@admin)

    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 8, municipality_ids: [ trencin.id ] }

    assert_response :success
    assert_equal [ trencin.name ], response.parsed_body["features"].map { it.dig("properties", "municipality_name") }
  end

  test "selected districts narrow the district layer and keep their municipality boundary" do
    other_district = MunicipalityDistrict.where(municipality: @bratislava).where.not(id: @stare_mesto.id).first
    create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: @bratislava, district: @stare_mesto, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: @bratislava, district: other_district, center_lat: 48.2, center_lon: 17.2)
    login(@admin)

    get admin_municipality_boundaries_path(format: :json), params: { kind: "district", z: 12, municipality_district_ids: [ @stare_mesto.id ] }
    assert_equal [ @stare_mesto.id ], response.parsed_body["features"].map { it.dig("properties", "municipality_district_id") }

    get admin_municipality_boundaries_path(format: :json), params: { kind: "district", z: 12, municipality_ids: [ @bratislava.id ] }
    assert_equal [ @stare_mesto.id, other_district.id ].sort, response.parsed_body["features"].map { it.dig("properties", "municipality_district_id") }.sort

    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 12, municipality_district_ids: [ @stare_mesto.id ] }
    assert_equal [ @bratislava.id ], response.parsed_body["features"].map { it.dig("properties", "municipality_id") }
  end

  test "is not available to non-admin users" do
    boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    login(users(:two))

    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 10, bbox: @bbox }
    assert_response :not_found

    get admin_municipality_boundary_path(boundary)
    assert_response :not_found
  end

  test "is not available to anonymous users" do
    boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)

    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 10, bbox: @bbox }
    assert_response :not_found

    get admin_municipality_boundary_path(boundary)
    assert_response :not_found
  end

  private

  def login(user)
    post "/login", params: { email: user.email, password: "password" }
    assert_response :redirect
  end
end
