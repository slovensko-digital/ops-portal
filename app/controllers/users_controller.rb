class UsersController < ApplicationController
  def show
    @user = User.where(anonymous: false).find(params[:id])
  end
end
