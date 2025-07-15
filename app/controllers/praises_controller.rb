class PraisesController < ApplicationController
  before_action :require_full_access_user
  before_action :ensure_user_onboarded
  before_action :check_rate_limit, only: [ :new, :create ]
  before_action :set_form_dependencies

  def new
    @praise = Praise.new
  end

  def create
    @praise = Praise.new(praise_params)

    @praise.author = current_user

    if @praise.save
      redirect_to thanks_praises_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def praise_params
    params.require(:praise).permit(:title, :description, :municipality_id, :public)
  end

  def set_form_dependencies
    @municipalities = Municipality.active.order(:name)
  end

  def check_rate_limit
    redirect_to_with_turbo please_wait_profile_path if current_user.create_issue_limit_exceeded?
  end
end
