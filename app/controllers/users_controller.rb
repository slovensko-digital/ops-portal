class UsersController < ApplicationController
  def show
    if params[:id].to_i == current_user.id
      redirect_to profile_path and return
    end

    begin
      @user = User.find(params[:id])

      if @user.anonymous?
        render :anonymous, status: :forbidden and return
      end

      @issues = @user.issues.publicly_visible.newest.page(params[:page]).per(8)
    rescue ActiveRecord::RecordNotFound
      render :not_found, status: :not_found
    end
  end
end
