class IssuesController < ApplicationController
  before_action :set_issue, only: %i[ show destroy ]

  # GET /issues or /issues.json
  def index
    @tab = params[:tab].in?(%w[map stats]) ? params[:tab] : "list"

    scope = Issue.publicly_visible
    case @tab
      when "list"
        scope = scope.order(reported_at: :desc) # TODO
        scope = scope.with_attached_photos.includes(:state)

        @search_results = search_engine.search(scope, params)
      when "map"
        @search_results = search_engine.search(scope, params)
      when "stats"
        @search_results = search_engine.stats(scope, params)
    end
  end

  # GET /issues/1 or /issues/1.json
  def show
  end

  # DELETE /issues/1 or /issues/1.json
  def destroy
    @issue.destroy!
    redirect_to issues_path, status: :see_other, notice: "Issue was successfully destroyed."
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_issue
    @issue = Issue.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def issue_params
    params.expect(issue: [ :title, :description, :author, :reported_at ])
  end

  private

  def search_engine
    SearchEngine.new(
      filters: [
        SearchEngine::SimpleFilter.new(
          :dopyt,
          filter: ->(scope, params) do
            map = {
              "Podnet" => :issue,
              "Pochvala" => :praise,
              "Otázka" => :question
            }

            scope.where(issue_type: map.values_at(*Array(params[:dopyt])))
          end,
          visible_filter_label: "Typ dopytu",
          items_finder: %w[Podnet Otázka Pochvala]
        ),

        SearchEngine::SimpleFilter.new(
          :stav,
          filter: ->(scope, params) { scope.joins(:state).where(state: { name: params[:stav] }) },
          visible_filter_label: "Stav podnetu",
          items_finder: -> { Issues::State.order(:name).pluck(:name) - %w[Čakajúci Neprijatý] },
        ),
        SearchEngine::SimpleFilter.new(
          :kategoria,
          filter: ->(scope, params) { scope.joins(:category).where(issues_categories: { name: params[:kategoria] }) },
          visible_filter_label: "Kategória",
          items_finder: -> { Issues::Category.order(:name).pluck(:name) },
        ),
        SearchEngine::SimpleFilter.new(
          :podkategoria,
          filter: ->(scope, params) { scope.joins(:subcategory).where(issues_subcategories: { name: params[:podkategoria] }) }
        ),
        SearchEngine::SimpleFilter.new(
          :typ,
          filter: ->(scope, params) { scope.joins(:subtype).where(issues_subtypes: { name: params[:typ] }) }
        ),
        SearchEngine::SimpleFilter.new(
          :zodpovedny,
          filter: ->(scope, params) { scope.joins(:responsible_subject).where(responsible_subject: { subject_name: params[:zodpovedny] }) }
        ),
        SearchEngine::SimpleFilter.new(
          :ulica,
          filter: ->(scope, params) { scope.where(address_street: params[:ulica]) }
        ),
        SearchEngine::SimpleFilter.new(
          :cast,
          filter: ->(scope, params) { scope.joins(:municipality_district).where(municipality_districts: { name: params[:cast] }) }
        ),
        SearchEngine::SimpleFilter.new(
          :obec,
          filter: ->(scope, params) { scope.joins(:municipality).where(municipalities: { name: params[:obec] }) }
        ),

        SearchEngine::SimpleFilter.new(
          :q,
          label: "Textové vyhľadávanie",
          filter: ->(scope, params) { scope.fulltext_search(params[:q]) }
        )
      ],
      per_page: 12,
    )
  end
end
