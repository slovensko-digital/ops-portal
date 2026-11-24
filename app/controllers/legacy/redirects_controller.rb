class Legacy::RedirectsController < ApplicationController
  before_action :set_legacy_visit_cookie
  before_action :set_municipality, only: [ :search_list, :search_street, :search_stats, :search_map ]

  rescue_from ActiveRecord::RecordNotFound, with: -> { render "errors/render_404", status: :not_found }

  def index
    redirect_to root_path, status: :moved_permanently
  end

  def search_list
    return redirect_to issues_path unless @municipality

    municipality_district = @municipality.municipality_districts.where("? = ANY(aliases)", params[:municipality_district_slug]).first
    redirect_to helpers.search_issues_path(lokalita: municipality_district || @municipality), status: :moved_permanently
  end

  def search_street
    return redirect_to issues_path unless @municipality

    street = Street.find_by!(legacy_id: params[:legacy_id])
    redirect_params = { lokalita: @municipality, ulica: street.name }

    if params[:status].present?
      state = Issues::State.find_by(legacy_id: params[:status])
      redirect_params[:stav] = state.name if state
    end

    redirect_to helpers.search_issues_path(redirect_params), status: :moved_permanently
  end

  def search_stats
    return redirect_to issues_path unless @municipality

    redirect_to helpers.search_issues_path(lokalita: @municipality, tab: "stats"), status: :moved_permanently
  end

  def search_map
    return redirect_to issues_path unless @municipality

    redirect_to helpers.search_issues_path(lokalita: @municipality, tab: "map"), status: :moved_permanently
  end

  def show_issue
    issue = Issue.find_by!(legacy_id: params[:legacy_id])

    redirect_to issue, status: :moved_permanently
  end

  def create_issue
    redirect_to cms_page_path("vitajte-na-novom-portali-odkaz-pre-starostu"), status: :moved_permanently
  end

  def show_user
    user = User.find_by!(legacy_id: params[:legacy_id])

    redirect_to user_path(user), status: :moved_permanently
  end

  private

  def set_municipality
    @municipality = Municipality.find_by("? = ANY(aliases)", params[:municipality_slug])
  end

  def set_legacy_visit_cookie
    cookies[:legacy_visit] = { value: 1, expires: 1.hour.from_now }
  end
end
