class UsersController < ApplicationController
  before_action :set_user
  before_action do
    render :anonymous, status: :forbidden if @user.anonymous?
  end

  rescue_from ActiveRecord::RecordNotFound, with: -> { render :not_found, status: :not_found }

  def show
    @issues = @user.issues.publicly_visible.newest.page(params[:page]).per(8)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
