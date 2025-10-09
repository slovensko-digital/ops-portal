class UsersController < ApplicationController
  before_action :redirect_if_self, only: :show
  before_action :set_user, only: :show
  before_action only: :show do
    render :anonymous, status: :forbidden if @user.anonymous?
  end

  rescue_from ActiveRecord::RecordNotFound, with: -> { render :not_found, status: :not_found }

  def show
    @issues = @user.issues.publicly_visible.newest.page(params[:page]).per(8)
  end

  def redirect_if_self
    return if current_user.is_a?(AnonymousUser)

    if params[:id].to_i == current_user.id
      redirect_to profile_path
    end
  end

  def set_user
    @user = User.find(params[:id])
  end
end
