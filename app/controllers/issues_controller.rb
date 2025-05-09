class IssuesController < ApplicationController
  before_action :ensure_user_onboarded
  before_action :set_issue, only: %i[ show edit update ]
  before_action :check_show_permissions, only: :show
  before_action :check_edit_permissions, only: %i[ edit update ]

  # GET /issues or /issues.json
  def index
    @tab = params[:tab].in?(%w[map stats]) ? params[:tab] : "list"

    scope = Issue.publicly_visible.includes(:state)
    case @tab
    when "list"
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
    @activity_objects = @issue.visible_activity_objects
  end

  def edit
  end

  def update
    @issue.assign_attributes(issue_params)
    if @issue.save
      SyncIssueToTriageJob.perform_later(@issue, sync_activities: false)
      redirect_to @issue
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_issue
    @issue = Issue.find(params.expect(:id))
  end

  def issue_params
    params.expect(issue: [ :title, :description, photos: [] ])
  end

  def check_show_permissions
    redirect_to root_path if !@issue.public? && !@issue.editable_by?(current_user)
  end

  def check_edit_permissions
    redirect_to root_path unless @issue.editable_by?(current_user)
  end

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

        SearchEngine::Controls::Dropdown.new(
          param_name: :obdobie,
          label: "Obdobie",
          default_label: "Celé",
          items: [
            "Posledných 30 dní",
            "Tento rok",
            "Minulý rok"
          ],
          multiple: false,
          sort: false,
          filter: ->(scope, params) do
            case params[:obdobie]
            when "Posledných 30 dní"
                scope = scope.where(created_at: 30.days.ago..)
            when "Tento rok"
                scope = scope.where(created_at: Date.current.beginning_of_year..)
            when "Minulý rok"
                scope = scope.where(created_at: 1.year.ago.beginning_of_year..1.year.ago.end_of_year)
            end

            scope
          end
        ),

        SearchEngine::Controls::SearchField.new(
          param_name: :q,
          label: "Textové vyhľadávanie",
          filter: ->(scope, params) do
            scope.fulltext_search(
              params[:q],
              against: [ :title, :description, :legacy_id, :id, :fulltext_extra ],
              unaccent_f: :f_unaccent
            )
          end,
        )
      ],

      sorts: [
        SearchEngine::Controls::Sort.new(
          name: :nove,
          label: "Najnovšie",
          apply_if: ->(params) do
            return false unless params[:sort].nil? || params[:sort] == "nove"
            return false if params[:pin].present? && (params[:sort].nil? || params[:sort] == "vzd")

            true
          end,
          order: ->(scope, _) { scope.order(created_at: :desc) }
        ),

        SearchEngine::Controls::Sort.new(
          name: :oblubene,
          label: "Najobľúbenejšie",
          order: ->(scope, _) { scope.order(likes_count: :desc, created_at: :desc) }
        ),

        SearchEngine::Controls::Sort.new(
          name: :komentare,
          label: "Najkomentovanejšie",
          order: ->(scope, _) { scope.order(comments_count: :desc, created_at: :desc) }
        ),

        SearchEngine::Controls::Sort.new(
          name: :zodpovedane,
          label: "Naposledy zodpovedané",
          order: ->(scope, _) do
            scope.where.not(responsible_subject_last_contact_at: nil)
              .order(responsible_subject_last_contact_at: :desc)
          end
        ),

        SearchEngine::Controls::Sort.new(
          name: :vzd,
          label: "Vzdialenosť",
          visible_if: ->(params) { params[:pin].present? },
          apply_if: ->(params) do
            return false unless params[:sort].nil? || params[:sort] == "vzd"
            return false unless params[:pin].present?

            true
          end,
          order: ->(scope, params) do
            lat, lon = params[:pin].split(",", 2).map(&:to_f)

            scope.order_by_distance_from_point(lat, lon)
          end
        )
      ],

      per_page: 12,
      default_permitted_params: [ "tab" ]
    )
  end
end
