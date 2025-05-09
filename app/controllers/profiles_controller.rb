class ProfilesController < ApplicationController
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @onboarding = !@user.onboarded?

    @user.assign_attributes(user_attributes)
    if @user.save(context: @onboarding ? :onboarding : :update)
      path = @user.onboarded_previously_changed? ? root_path : profile_path
      redirect_to path, notice: "Zmeny profilu boli uložené."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_attributes
    params.require(:user).permit(:name, :anonymous, :municipality_id, :email_notifiable, :birth_year, :terms_of_service, :newsletter_accepted, :gdpr_stats_accepted, :onboarded)
  end
end
