class ProfilesController < ApplicationController
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.assign_attributes(user_attributes)
    if @user.save
      redirect_to profile_path, notice: "Zmeny boli uložené."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_attributes
    params.require(:user).permit(:name, :anonymous, :municipality_id, :email_notifiable, :birth_year, :gdpr_stats_accepted)
  end
end
