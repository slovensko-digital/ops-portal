class Issues::Drafts::GeosController < ApplicationController
  include Issues::DraftScoped

  def show
    @draft.load_geo_from_exif(@draft.photos.first) unless @draft.geo.present?
  end

  def update
    if @draft.update(geo_params)
      redirect_to issues_draft_suggestions_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def geo_params
    params.expect(issues_draft: [ :longitude, :latitude, :address_house_number, :address_road, :address_neighbourhood,
                                  :address_town, :address_suburb, :address_city_district, :address_city, :address_state,
                                  :address_postcode, :address_country, :address_country_code ])
  end
end
