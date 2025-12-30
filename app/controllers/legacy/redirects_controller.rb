class Legacy::RedirectsController < ApplicationController
  before_action :set_legacy_visit_cookie
  before_action :set_municipality, only: [ :search_list, :search_street, :search_stats, :search_map ]

  def index
    redirect_to root_path
  end

  def search_list
    return redirect_to issues_path unless @municipality

    municipality_district = @municipality.municipality_districts.where("? = ANY(aliases)", params[:municipality_district_slug]).first
    if municipality_district
      redirect_to issues_path(obec: @municipality.name, cast: municipality_district.name)
    else
      redirect_to issues_path(obec: @municipality.name)
    end
  end

  def search_street
    return redirect_to issues_path unless @municipality

    street = Street.find_by!(legacy_id: params[:legacy_id])
    redirect_params = { obec: @municipality.name, ulica: street.name }

    if params[:status].present?
      state = Issues::State.find_by(legacy_id: params[:status])
      redirect_params[:stav] = state.name if state
    end

    redirect_to issues_path(redirect_params)
  end

  def search_stats
    return redirect_to issues_path unless @municipality

    redirect_to issues_path(obec: @municipality.name, tab: "stats")
  end

  def search_map
    return redirect_to issues_path unless @municipality

    redirect_to issues_path(obec: @municipality.name, tab: "map")
  end

  def show_issue
    issue = Issue.find_by!(legacy_id: params[:legacy_id])

    redirect_to issue
  end

  def create_issue
    redirect_to cms_page_path("vitajte-na-novom-portali-odkaz-pre-starostu")
  end

  def show_user
    user = User.find_by!(legacy_id: params[:legacy_id])

    redirect_to user
  end

  private

  def set_municipality
    @municipality = Municipality.find_by("? = ANY(aliases)", params[:municipality_slug])
  end

  def set_legacy_visit_cookie
    cookies[:legacy_visit] = { value: 1, expires: 1.hour.from_now }
  end
end
