# == Schema Information
#
# Table name: municipality_boundaries
#
#  id                       :bigint           not null, primary key
#  municipality_district_id :bigint
#  municipality_id          :bigint
#  boundary                 :geometry         not null
#  boundary_kind            :string           default("municipality"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class MunicipalityBoundary < ApplicationRecord
  KINDS = %w[municipality district].freeze
  MAP_TILE_SIZE = 256
  MAP_MAX_ZOOM = 19
  MATCHED_SQL = "(CASE municipality_boundaries.boundary_kind WHEN 'district' " \
                "THEN municipality_boundaries.municipality_district_id IS NOT NULL " \
                "ELSE municipality_boundaries.municipality_id IS NOT NULL END)".freeze

  belongs_to :municipality, optional: true
  belongs_to :municipality_district, optional: true

  scope :district_boundaries, -> { where(boundary_kind: "district") }
  scope :districts, -> { district_boundaries.where.not(municipality_district_id: nil) }
  scope :municipalities, -> { where(boundary_kind: "municipality").where.not(municipality_id: nil) }
  scope :unmatched_municipalities, -> { where(boundary_kind: "municipality", municipality_id: nil) }
  scope :unmatched_districts, -> { district_boundaries.where(municipality_district_id: nil) }

  scope :matched, -> { where(MATCHED_SQL) }
  scope :unmatched, -> { where.not(MATCHED_SQL) }
  scope :within_bbox, ->(min_lon, min_lat, max_lon, max_lat) {
    where("boundary && ST_MakeEnvelope(?, ?, ?, ?, 4326)", min_lon, min_lat, max_lon, max_lat)
  }
  scope :with_municipality_active, ->(active) { where(municipality_id: Municipality.where(active: active).select(:id)) }

  scope :with_bounds, -> {
    select(:id, "ST_XMin(boundary) AS min_lon", "ST_YMin(boundary) AS min_lat", "ST_XMax(boundary) AS max_lon", "ST_YMax(boundary) AS max_lat")
  }

  # [[south, west], [north, east]], needs the with_bounds scope
  def bounds
    [ [ self[:min_lat], self[:min_lon] ], [ self[:max_lat], self[:max_lon] ] ]
  end

  # Boundaries with the names and flags shown on the map and their outline as GeoJSON in "geojson",
  # simplified to about one pixel at the given zoom, so the geometry is not more detailed than the map can show.
  def self.map_features(zoom:)
    # map tiles are 256 pixels wide and the world, 360 degrees of longitude, is one tile wide at zoom 0
    # and doubles with every zoom level
    degrees_per_pixel = 360.0 / (MAP_TILE_SIZE * 2**zoom.to_i.clamp(0, MAP_MAX_ZOOM))

    left_joins(:municipality, :municipality_district).select(
      "municipality_boundaries.id",
      "municipality_boundaries.boundary_kind",
      "municipality_boundaries.municipality_id",
      "municipality_boundaries.municipality_district_id",
      "municipalities.name AS municipality_name",
      "municipalities.active AS municipality_active",
      "municipality_districts.name AS municipality_district_name",
      sanitize_sql([ "ST_AsGeoJSON(ST_SimplifyPreserveTopology(boundary, ?), 5) AS geojson", degrees_per_pixel ])
    )
  end

  def matched?
    boundary_kind == "district" ? municipality_district_id.present? : municipality_id.present?
  end

  scope :containing_point, ->(latitude, longitude) {
    where(
      "ST_Covers(boundary, ST_SetSRID(ST_MakePoint(?, ?), 4326))",
      longitude, latitude
    )
  }
end
