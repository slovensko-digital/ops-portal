class Issues::DraftsController < ApplicationController
  before_action :set_user

  def new
    @draft = Issues::Draft.new
  end

  def create
    @draft = Issues::Draft.new(draft_params)
    @draft.author = @user
    if @draft.save(context: :photos_step)
      @draft.schedule_calculate_suggestions # TODO move somehow to after_save
      redirect_to issues_draft_geo_path(@draft)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @draft = Issues::Draft.find(params[:id])
  end

  def confirm
    @draft = Issues::Draft.find(params[:draft_id])

    @draft.confirm

    redirect_to @draft
  end

  private

  def draft_params
    params.expect(issues_draft: [ photos: [] ])
  end

  def set_user
    # TODO: choose real user
    @user = User.find_or_create_by(
      email: ENV.fetch("DEFAULT_USER_EMAIL"),
      zammad_identifier: ENV.fetch("DEFAULT_USER_ZAMMAD_IDENTIFIER"),
      firstname: ENV.fetch("DEFAULT_USER_FIRSTNAME"),
      lastname: ENV.fetch("DEFAULT_USER_LASTNAME")
    )
  end
end
