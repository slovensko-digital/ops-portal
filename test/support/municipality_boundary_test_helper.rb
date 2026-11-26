module MunicipalityBoundaryTestHelper
  def create_municipality_boundary(municipality:, district: nil, center_lat:, center_lon:, size: 0.1, boundary_kind: nil)
    min_lon = center_lon - size
    max_lon = center_lon + size
    min_lat = center_lat - size
    max_lat = center_lat + size

    MunicipalityBoundary.create!(
      municipality: municipality,
      municipality_district: district,
      boundary_kind: boundary_kind || (district.present? ? "district" : "municipality"),
      boundary: "SRID=4326;POLYGON((#{min_lon} #{min_lat}, #{max_lon} #{min_lat}, #{max_lon} #{max_lat}, #{min_lon} #{max_lat}, #{min_lon} #{min_lat}))"
    )
  end
end
