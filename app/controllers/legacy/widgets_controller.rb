class Legacy::WidgetsController < ApplicationController
  before_action :set_municipality
  before_action :set_options

  def index
    @width = params[:width].to_i > 0 ? params[:width].to_i : 290
    @theme = case params[:theme]
    when "grey"
      "grey"
    when "stavebna_policia"
      "stavebnapolicia"
    else
      ""
    end
    @background = params[:bg] if params[:bg]&.match?(/\A[0-9a-fA-F]{6}\z/) || params[:bg]&.match?(/\A[0-9a-fA-F]{3}\z/)

    @feed = fetch_feed
    @statistics = calculate_statistics if @width > 250

    # Allow widget to be embedded in iframes from any domain and enable JavaScript
    response.headers["X-Frame-Options"] = "ALLOWALL"
    response.headers["Content-Security-Policy"] = "frame-ancestors *; script-src 'self' 'unsafe-inline' 'unsafe-eval' https: http:; img-src 'self' https: http: data: blob:"

    render layout: false
  end

  private

  def set_municipality
    # widget=banska-bystrica
    # widget=banska-bystrica/banska-bystrica-sever
    if params[:widget].present?
      municipality_slug, district_slug = params[:widget].to_s.split("/")
      @municipality = Municipality.find_by("? = ANY(aliases)", municipality_slug)

      if district_slug.present? && @municipality
        @municipality_district = @municipality.municipality_districts.where("? = ANY(aliases)", district_slug).first
      end
    end
  end

  def set_options
    @options = {}
    @options[:municipality_id] = @municipality.id if @municipality
    @options[:municipality_district_id] = @municipality_district.id if @municipality_district

    # Fallback to explicit param if provided
    if params[:municipality_district_slug].present? && @municipality && @municipality_district.nil?
      @municipality_district = @municipality.municipality_districts.where("? = ANY(aliases)", params[:municipality_district_slug]).first
      @options[:municipality_district_id] = @municipality_district.id if @municipality_district
    end

    @options[:responsible_subject_id] = ResponsibleSubject.where(legacy_id: params[:zodpovednost]).pluck(:id) if params[:zodpovednost].present?

    if params[:status].present?
      status_ids = params[:status].is_a?(Array) ? params[:status] : [ params[:status] ]
      @options[:state_ids] = Issues::State.where(legacy_id: status_ids).pluck(:id)
    end

    @options[:category_id] = Issues::Category.where(legacy_id: params[:kategoria]).pluck(:id) if params[:kategoria].present?
    @options[:limit] = params[:limit].to_i > 0 && params[:limit].to_i <= 16 ? params[:limit].to_i : 3
  end

  def fetch_feed
    scope = Issue.publicly_visible.includes(:state, :category, :municipality_district, :responsible_subject, photos_attachments: :blob)

    scope = scope.where(municipality_id: @options[:municipality_id]) if @options[:municipality_id]
    scope = scope.where(municipality_district_id: @options[:municipality_district_id]) if @options[:municipality_district_id]
    scope = scope.where(responsible_subject_id: @options[:responsible_subject_id]) if @options[:responsible_subject_id]
    scope = scope.where(state_id: @options[:state_ids]) if @options[:state_ids]
    scope = scope.where(category_id: @options[:category_id]) if @options[:category_id]

    scope.order(created_at: :desc).limit(@options[:limit])
  end

  def calculate_statistics
    base_scope = Issue.publicly_visible.joins(:state)

    base_scope = base_scope.where(municipality_id: @options[:municipality_id]) if @options[:municipality_id]
    base_scope = base_scope.where(municipality_district_id: @options[:municipality_district_id]) if @options[:municipality_district_id]
    base_scope = base_scope.where(responsible_subject_id: @options[:responsible_subject_id]) if @options[:responsible_subject_id]

    # State IDs - assuming legacy mapping: 1 = solved, 2 = unresolved, 3 = in_progress
    solved_states = Issues::State.where(key: [ "resolved" ]).pluck(:id)
    unsolved_states = Issues::State.where(key: [ "unresolved" ]).pluck(:id)
    open_states = Issues::State.where(key: [ "in_progress" ]).pluck(:id)

    {
      total: {
        solved: base_scope.where(state_id: solved_states).count,
        unsolved: base_scope.where(state_id: unsolved_states).count,
        open: base_scope.where(state_id: open_states).count
      },
      last_month: {
        solved: base_scope.where(state_id: solved_states).where(resolution_started_at: 30.days.ago..).count,
        unsolved: base_scope.where(state_id: unsolved_states).where(resolution_started_at: 30.days.ago..).count,
        open: base_scope.where(state_id: open_states).where(resolution_started_at: 30.days.ago..).count
      },
      previous_month: {
        solved: base_scope.where(state_id: solved_states).where(resolution_started_at:  60.days.ago..30.days.ago).count,
        unsolved: base_scope.where(state_id: unsolved_states).where(resolution_started_at:  60.days.ago..30.days.ago).count,
        open: base_scope.where(state_id: open_states).where(resolution_started_at:  60.days.ago..30.days.ago).count
      }
    }
  end
end
