class Issues::DraftsController < ApplicationController
  before_action :require_user
  before_action :load_draft, except: [ :new, :create, :thanks ]

  def new
    @draft = Issues::Draft.new
  end

  def edit
    render :new
  end

  def create
    @draft = Issues::Draft.new(draft_params)
    @draft.author = current_user
    if @draft.save(context: :photos_step)
      @draft.schedule_calculate_suggestions # TODO move somehow to after_save
      redirect_to issues_draft_geo_path(@draft)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @draft.photos.attach(draft_params[:photos])
    if @draft.save(context: :photos_step)
      redirect_to edit_issues_draft_path(@draft, next: params[:next])
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy_photo
    @draft.photos.find(params[:photo_id]).purge
    redirect_to edit_issues_draft_path(@draft, next: params[:next])
  end

  def thanks
  end

  private

  def draft_params
    params.expect(issues_draft: [ photos: [] ])
  end

  def load_draft
    @draft = current_user.issues_drafts.find(params[:id] || params[:draft_id])
  end
end
