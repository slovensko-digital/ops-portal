class UsersController < ApplicationController
  def show
    if params[:id].to_i == current_user.id
      redirect_to profile_path and return
    end

    @user = User.where(anonymous: false).find(params[:id])
    @issues = @user.issues.publicly_visible.newest.page(params[:page]).per(8)
  end
end
