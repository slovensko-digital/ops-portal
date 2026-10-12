# Access is restricted to admins by the GoodJobAdmin route constraint.
class Admin::MunicipalityBoundariesController < ApplicationController
  KINDS = { "municipality" => "Obce", "district" => "Mestské časti" }.freeze
  MATCHED_STATUSES = { "active" => "Aktívne", "inactive" => "Neaktívne" }.freeze
  UNMATCHED_STATUS = { "unmatched" => "Nespárované" }.freeze
  STATUSES = MATCHED_STATUSES.merge(UNMATCHED_STATUS).freeze

  layout "admin"

  def index
    respond_to do |format|
      format.html do
        # "kind:status" pairs, e.g. "municipality:active"; all municipality boundaries by default.
        # An empty "boundaries[]=" means nothing is selected and is kept so a shared link shows the same map.
        @boundaries = params.key?(:boundaries) ? Array(params[:boundaries]).compact_blank : STATUSES.keys.map { "municipality:#{it}" }
        @selected_boundary = selected_boundary
        @municipality_ids = Array(params[:municipality_ids]).compact_blank.map(&:to_i)
        @municipality_district_ids = Array(params[:municipality_district_ids]).compact_blank.map(&:to_i)
        @municipalities = municipalities_with_boundaries
        @districts_by_municipality_id = districts_with_boundaries.group_by(&:municipality_id)
      end
      format.json { render json: feature_collection }
    end
  end

  def show
    @boundary = MunicipalityBoundary.includes(:municipality, :municipality_district).find(params[:id])
  end

  private

  def selected_boundary
    id, kind, min_lon, min_lat, max_lon, max_lat = MunicipalityBoundary.where(id: params[:boundary]).pick(
      :id, :boundary_kind, Arel.sql("ST_XMin(boundary)"), Arel.sql("ST_YMin(boundary)"), Arel.sql("ST_XMax(boundary)"), Arel.sql("ST_YMax(boundary)")
    )
    return {} unless id

    { id: id, kind: kind, bounds: [ [ min_lat, min_lon ], [ max_lat, max_lon ] ] }
  end

  def municipalities_with_boundaries
    Municipality
      .where(id: MunicipalityBoundary.select(:municipality_id))
      .order(Arel.sql("name COLLATE unicode"))
      .select(:id, :name, :active)
  end

  def districts_with_boundaries
    MunicipalityDistrict
      .where(id: MunicipalityBoundary.select(:municipality_district_id))
      .order(Arel.sql("name COLLATE unicode"))
      .select(:id, :municipality_id, :name)
  end

  def feature_collection
    kind = params[:kind].presence_in(KINDS.keys) || "municipality"
    # roughly one pixel at the requested zoom, so the geometry is not more detailed than the map can show
    tolerance = 360.0 / (256 * 2**params[:z].to_i.clamp(0, 19))

    scope = MunicipalityBoundary
      .where(boundary_kind: kind)
      .left_joins(:municipality, :municipality_district)
    scope = filter_by_status(scope, kind)
    scope = filter_by_selection(scope, kind)

    if params[:bbox].present?
      min_lon, min_lat, max_lon, max_lat = params[:bbox].split(",").map(&:to_f)
      scope = scope.where("boundary && ST_MakeEnvelope(?, ?, ?, ?, 4326)", min_lon, min_lat, max_lon, max_lat)
    end

    rows = scope
      .pluck(
        :id, :municipality_id, :municipality_district_id, "municipalities.name", "municipalities.active", "municipality_districts.name",
        Arel.sql(MunicipalityBoundary.sanitize_sql([ "ST_AsGeoJSON(ST_SimplifyPreserveTopology(boundary, ?), 5)", tolerance ]))
      )

    {
      type: "FeatureCollection",
      features: rows.map do |id, municipality_id, district_id, municipality_name, municipality_active, district_name, geometry|
        {
          type: "Feature",
          geometry: JSON.parse(geometry),
          properties: {
            id: id,
            kind: kind,
            municipality_id: municipality_id,
            municipality_name: municipality_name,
            municipality_active: municipality_active,
            municipality_district_id: district_id,
            municipality_district_name: district_name,
            matched: kind == "district" ? district_id.present? : municipality_id.present?
          }
        }
      end
    }
  end

  # Matched boundaries are split by the active flag of their municipality, district boundaries included.
  def filter_by_status(scope, kind)
    statuses = Array(params[:statuses]) & STATUSES.keys
    return scope if statuses.empty?

    matched_column = kind == "district" ? :municipality_district_id : :municipality_id

    statuses.map do |status|
      case status
      when "active" then scope.where.not(matched_column => nil).where(municipalities: { active: true })
      when "inactive" then scope.where.not(matched_column => nil).where(municipalities: { active: false })
      when "unmatched" then scope.where(matched_column => nil)
      end
    end.reduce(:or)
  end

  # A selected municipality shows its own boundary and all of its districts. Selecting some of its districts
  # narrows the district layer down to those, while the municipality boundary stays visible.
  def filter_by_selection(scope, kind)
    municipality_ids = Array(params[:municipality_ids]).compact_blank.map(&:to_i)
    district_ids = Array(params[:municipality_district_ids]).compact_blank.map(&:to_i)
    return scope if municipality_ids.empty? && district_ids.empty?

    municipality_ids_of_districts = MunicipalityDistrict.where(id: district_ids).distinct.pluck(:municipality_id)

    if kind == "district"
      scope.where(municipality_district_id: district_ids)
        .or(scope.where(municipality_id: municipality_ids - municipality_ids_of_districts))
    else
      scope.where(municipality_id: municipality_ids | municipality_ids_of_districts)
    end
  end
end
