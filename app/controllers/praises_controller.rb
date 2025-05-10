class PraisesController < ApplicationController
  before_action :require_full_access_user
  before_action :ensure_user_onboarded
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
    params.require(:praise).permit(:title, :description, :municipality_id, :praise_public)
  end

  def set_form_dependencies
    @municipalities = Municipality.active.order(:name)
  end
end
