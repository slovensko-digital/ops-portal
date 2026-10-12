# Filters boundaries shown on the admin boundaries map. A list left out (nil) keeps all of its options,
# an empty list keeps none.
class MunicipalityBoundary::AdminFilter
  MATCHED = %w[matched unmatched].freeze
  ACTIVE = %w[true false].freeze

  attr_reader :kinds, :matched, :active, :municipality_ids, :municipality_district_ids

  def initialize(kinds: nil, matched: nil, active: nil, municipality_ids: [], municipality_district_ids: [], bbox: nil)
    @kinds = options(kinds, MunicipalityBoundary::KINDS)
    @matched = options(matched, MATCHED)
    @active = options(active, ACTIVE)
    @municipality_ids = Array(municipality_ids).compact_blank.map(&:to_i)
    @municipality_district_ids = Array(municipality_district_ids).compact_blank.map(&:to_i)
    @bbox = parse_bbox(bbox)
  end

  # The active flag only applies to matched boundaries, unmatched ones have no municipality to check.
  def boundaries
    scopes = []
    scopes << by_active(base.matched) if matched.include?("matched")
    scopes << base.unmatched if matched.include?("unmatched")
    scopes.reduce(:or) || MunicipalityBoundary.none
  end

  # The boundaries as a GeoJSON FeatureCollection string with the names and flags shown on the map. It is built
  # in Postgres, so the outlines are not parsed and serialized again in Ruby. Outlines are simplified to about
  # one pixel at the given zoom, so the geometry is not more detailed than the map can show.
  def map_feature_collection(zoom:)
    tolerance = 360.0 / (256 * 2**zoom.to_i.clamp(0, 19))

    features = boundaries.left_joins(:municipality, :municipality_district).select(MunicipalityBoundary.sanitize_sql([ <<~SQL, tolerance ]))
      json_build_object(
        'type', 'Feature',
        'geometry', ST_AsGeoJSON(ST_SimplifyPreserveTopology(boundary, ?), 5)::json,
        'properties', json_build_object(
          'id', municipality_boundaries.id,
          'kind', municipality_boundaries.boundary_kind,
          'municipality_id', municipality_boundaries.municipality_id,
          'municipality_name', municipalities.name,
          'municipality_active', municipalities.active,
          'municipality_district_id', municipality_boundaries.municipality_district_id,
          'municipality_district_name', municipality_districts.name,
          'matched', #{MunicipalityBoundary::MATCHED_SQL}
        )
      ) AS feature
    SQL

    MunicipalityBoundary.connection.select_value(<<~SQL)
      SELECT json_build_object('type', 'FeatureCollection', 'features', COALESCE(json_agg(feature), '[]'::json))::text
      FROM (#{features.to_sql}) features
    SQL
  end

  private

  def options(values, all)
    values.nil? ? all : Array(values).compact_blank & all
  end

  # a bbox that is not 4 numbers is ignored
  def parse_bbox(bbox)
    coordinates = bbox.to_s.split(",").map { Float(it, exception: false) }
    coordinates if coordinates.size == 4 && coordinates.all?
  end

  def base
    return MunicipalityBoundary.none if kinds.empty?

    scope = MunicipalityBoundary.left_joins(:municipality, :municipality_district)
    scope = scope.where("boundary && ST_MakeEnvelope(?, ?, ?, ?, 4326)", *@bbox) if @bbox
    kinds.map { by_selection(scope.where(boundary_kind: it), it) }.reduce(:or)
  end

  # district boundaries are filtered by the active flag of the municipality they belong to
  def by_active(scope)
    return scope if (ACTIVE - active).empty?

    scope.where(municipalities: { active: active.map { it == "true" } })
  end

  # A selected municipality shows its own boundary and all of its districts. Selecting some of its districts
  # narrows the district layer down to those, while the municipality boundary stays visible.
  def by_selection(scope, kind)
    return scope if municipality_ids.empty? && municipality_district_ids.empty?

    if kind == "district"
      scope.where(municipality_district_id: municipality_district_ids)
        .or(scope.where(municipality_id: municipality_ids - municipality_ids_of_districts))
    else
      scope.where(municipality_id: municipality_ids | municipality_ids_of_districts)
    end
  end

  def municipality_ids_of_districts
    @municipality_ids_of_districts ||= MunicipalityDistrict.where(id: municipality_district_ids).distinct.pluck(:municipality_id)
  end
end
