class Issues::Drafts::DuplicatesController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def index
    @issues = @draft.potential_duplicates
      .order_by_distance_from_point(@draft.latitude, @draft.longitude)
      .includes(:state, :municipality, :municipality_district)
      .with_attached_photos
  end
end
