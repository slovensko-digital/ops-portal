class Issues::Drafts::DuplicatesController < ApplicationController
  before_action :require_full_access_user
  before_action :ensure_citizen
  include Issues::DraftScoped
  before_action :set_issue, only: [ :show, :update ]
  before_action :check_rate_limit, only: [ :show, :update ]

  def index
    @issues = @draft.potential_duplicates
      .order_by_distance_from_point(@draft.latitude, @draft.longitude)
      .includes(:state, :municipality, :municipality_district)
      .with_attached_photos

    @header_finish_draft = @draft
  end

  def show
    @update = Issues::Update.new(text: @draft.description, attachments: @draft.photos.blobs)
  end

  def update
    @update = @draft.submit_as_update_of(@issue, **update_params)

    if @update.persisted?
      Issues::SyncEditableActivityToTriageJob.perform_later(@update, sync_job: SyncIssueActivityObjectToTriageJob)
      flash[:notice] = "Podnet bol odoslaný ako aktualizácia už existujúceho podnetu"
      redirect_to_with_turbo issue_path(@issue)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_issue
    @issue = @draft.potential_duplicates.find(params[:id])
  end

  def update_params
    params.expect(issues_update: [ :text, attachments: [] ]).to_h.symbolize_keys.reverse_merge(text: nil, attachments: [])
  end

  def check_rate_limit
    redirect_to_with_turbo please_wait_profile_path if current_user.create_issue_update_limit_exceeded?
  end
end
