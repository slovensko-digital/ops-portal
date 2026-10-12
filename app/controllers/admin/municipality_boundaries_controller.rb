# Access is restricted to admins by the GoodJobAdmin route constraint.
class Admin::MunicipalityBoundariesController < ApplicationController
  KINDS = { "municipality" => "Obce", "district" => "Mestské časti" }.freeze
  MATCHED_OPTIONS = { "matched" => "Spárované", "unmatched" => "Nespárované" }.freeze
  ACTIVE_OPTIONS = { "true" => "Aktívne", "false" => "Neaktívne" }.freeze

  layout "admin_map"

  def index
    respond_to do |format|
      format.html do
        @filter = filter
        @selected_boundary = selected_boundary
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

  # An option list missing from the params keeps all options, an empty one ("kinds[]=") keeps none,
  # so a shared link shows the same map.
  def filter(kinds: params[:kinds], bbox: nil)
    MunicipalityBoundary::AdminFilter.new(
      kinds: kinds,
      matched: params[:matched],
      active: params[:active],
      municipality_ids: params[:municipality_ids],
      municipality_district_ids: params[:municipality_district_ids],
      bbox: bbox
    )
  end

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

    rows = filter(kinds: [ kind ], bbox: params[:bbox]).boundaries.pluck(
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
end
