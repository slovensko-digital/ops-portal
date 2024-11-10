class Issues::Drafts::GeosController < ApplicationController
  before_action :set_draft

  def show
    @draft.load_geo_from_exif(@draft.photos.first) unless @draft.geo.present?
  end

  def update
    if @draft.update(geo_params)
      redirect_to @draft
    else
      render :show
    end
  end

  private

  def set_draft
    @draft = Issues::Draft.find(params[:draft_id])
  end

  def geo_params
    params.expect(issues_draft: [:longitude, :latitude])
  end
end
