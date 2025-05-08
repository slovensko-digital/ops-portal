class Legacy::RedirectsController < ApplicationController
  before_action :set_legacy_visit_cookie

  def index
    redirect_to root_path
  end

  def search_list
    municipality = Municipality.find_by("? = ANY(aliases)", params[:municipality_slug])

    redirect_to issues_path(obec: municipality.name)
  end

  def search_stats
    municipality = Municipality.find_by("? = ANY(aliases)", params[:municipality_slug])

    redirect_to issues_path(obec: municipality.name, tab: "stats")
  end

  def show_issue
    issue = Issue.find_by!(legacy_id: params[:legacy_id])

    redirect_to issue
  end

  def create_issue
    redirect_to cms_page_path("vitajte-na-novom-portali-odkaz-pre-starostu")
  end

  private

  def set_legacy_visit_cookie
    cookies[:legacy_visit] = { value: 1, expires: 1.hour.from_now }
  end
end
