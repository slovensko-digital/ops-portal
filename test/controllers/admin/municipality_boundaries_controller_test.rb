require "test_helper"

class Admin::MunicipalityBoundariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @original_admin_emails = ENV["ADMIN_EMAILS"]
    ENV["ADMIN_EMAILS"] = @admin.email

    @bratislava = municipalities(:bratislava)
    @bratislava.update!(active: true)
    @bbox = "16.9,48.0,17.3,48.3"
  end

  teardown do
    ENV["ADMIN_EMAILS"] = @original_admin_emails
  end

  test "returns filtered boundaries in the bbox as GeoJSON" do
    boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: nil, center_lat: 48.15, center_lon: 17.1)
    create_municipality_boundary(municipality: municipalities(:trencin), center_lat: 48.9, center_lon: 18.04)
    login(@admin)

    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", matched: [ "matched" ], z: 10, bbox: @bbox }

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

  test "is not available to non-admin users" do
    boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    login(users(:two))

    assert_admin_routes_not_found(boundary)
  end

  test "is not available to anonymous users" do
    boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)

    assert_admin_routes_not_found(boundary)
  end

  private

  def login(user)
    post "/login", params: { email: user.email, password: "password" }
    assert_response :redirect
  end

  def assert_admin_routes_not_found(boundary)
    get admin_municipality_boundaries_path(format: :json), params: { kind: "municipality", z: 10, bbox: @bbox }
    assert_response :not_found

    get admin_municipality_boundary_path(boundary)
    assert_response :not_found
  end
end
