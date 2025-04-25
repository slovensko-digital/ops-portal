class IssuesController < ApplicationController
  before_action :set_issue, only: %i[ show destroy ]

  # GET /issues or /issues.json
  def index
    @tab = params[:tab].in?(%w[map stats]) ? params[:tab] : "list"

    scope = Issue.publicly_visible
    case @tab
    when "list"
        scope = scope.order(created_at: :desc) # TODO
        scope = scope.with_attached_photos

        @search_results = search_engine.search(scope, params)
    when "map"
        @search_results = search_engine.search(scope, params) # TODO
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
    params.expect(issue: [ :title, :description, :author, :created_at ])
  end

  private

  def search_engine
    SearchEngine.new(
      filters: [
        SearchEngine::Controls::Dropdown.new(
          param_name: :dopyt,
          label: "Typ dopytu",
          items: %w[Podnet Otázka Pochvala],
          filter: ->(scope, params) do
            map = {
              "Podnet" => :issue,
              "Pochvala" => :praise,
              "Otázka" => :question
            }

            scope.where(issue_type: map.values_at(*Array(params[:dopyt])))
          end,
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :stav,
          label: "Stav podnetu",
          items: -> { Issues::State.order(:name).pluck(:name) - %w[Čakajúci Neprijatý] },
          filter: ->(scope, params) { scope.joins(:state).where(state: { name: params[:stav] }) },
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :kategoria,
          label: "Kategória",
          items: -> { Issues::Category.order(:name).pluck(:name) },
          filter: ->(scope, params) { scope.joins(:category).where(issues_categories: { name: params[:kategoria] }) },
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :podkategoria,
          label: "Podkategória",
          items: ->(params) do
            return [] unless params[:kategoria]

            Issues::Subcategory.joins(:category)
              .where(issues_categories: { name: params[:kategoria] })
              .order(:name)
              .pluck(:name)
              .uniq
          end,
          filter: ->(scope, params) { scope.joins(:subcategory).where(issues_subcategories: { name: params[:podkategoria] }) }
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :typ,
          filter: ->(scope, params) { scope.joins(:subtype).where(issues_subtypes: { name: params[:typ] }) }
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :zodpovedny,
          filter: ->(scope, params) { scope.joins(:responsible_subject).where(responsible_subject: { subject_name: params[:zodpovedny] }) }
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :ulica,
          filter: ->(scope, params) { scope.where(address_street: params[:ulica]) }
        ),

        SearchEngine::Controls::Hidden.new(
          param_name: :pin,
          filter_label: "vzdialenosť do 500m",
          filter: ->(scope, params) do
            return scope unless params[:pin].present?

            distance = 500

            lat, lon = params[:pin].split(",", 2).map(&:to_f)

            if params[:tab].blank? || params[:tab] == "list"
              scope = scope.order_by_distance_from_point(lat, lon)
            end

            scope.within_distance_from_point(lat, lon, distance)
          end
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :obec,
          label: "Obec",
          items: -> { Municipality.active.order(:name).pluck(:name) },
          filter: ->(scope, params) { scope.joins(:municipality).where(municipalities: { name: params[:obec] }) }
        ),

        SearchEngine::Controls::Dropdown.new(
          param_name: :cast,
          label: "Mestská časť",
          items: ->(params) do
            return [] unless params[:obec].present?

            MunicipalityDistrict.joins(:municipality)
              .where(municipalities: { name: params[:obec], active: true })
              .order(:name)
              .pluck(:name)
          end,
          filter: ->(scope, params) { scope.joins(:municipality_district).where(municipality_districts: { name: params[:cast] }) }
        ),

        SearchEngine::Controls::SearchField.new(
          param_name: :q,
          label: "Textové vyhľadávanie",
          filter: ->(scope, params) { scope.fulltext_search(params[:q]) },
        )
      ],

      per_page: 12,
      default_permitted_params: [ "tab" ]
    )
  end
end
