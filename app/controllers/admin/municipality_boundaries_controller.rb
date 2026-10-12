# Access is restricted to admins by the GoodJobAdmin route constraint.
class Admin::MunicipalityBoundariesController < ApplicationController
  layout "admin_map"

  def index
    @filter = MunicipalityBoundary::AdminFilter.new(**filter_params)

    respond_to do |format|
      format.html do
        @selected_boundary = MunicipalityBoundary.with_bounds.find_by(id: params[:boundary])
        @municipalities = Municipality.with_boundaries.alphabetical
        @districts_by_municipality_id = MunicipalityDistrict.with_boundaries.alphabetical.group_by(&:municipality_id)
      end
      format.json { @boundaries = @filter.map_features(zoom: params[:z]) }
    end
  end

  def show
    @boundary = MunicipalityBoundary.includes(:municipality, :municipality_district).find(params[:id])
  end

  private

  # An option list missing from the params keeps all options, an empty one ("kinds[]=") keeps none,
  # so a shared link shows the same map.
  def filter_params
    {
      kinds: params[:kinds],
      matched: params[:matched],
      active: params[:active],
      municipality_ids: params[:municipality_ids],
      municipality_district_ids: params[:municipality_district_ids],
      bbox: params[:bbox]
    }
  end
end
