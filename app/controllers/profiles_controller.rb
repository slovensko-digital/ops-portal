class ProfilesController < ApplicationController
  before_action :require_user, except: [ :please_create ]
  before_action :set_user, except: [ :please_create, :please_verify ]

  before_action :ensure_citizen, only: [ :edit, :update, :settings, :watched_issues ]

  def please_create
  end

  def please_verify
  end

  def please_wait
  end

  def show
    @tab = :my
    @issues = current_user.issues.newest.page(params[:page]).per(8)
  end

  def watched_issues
    @tab = :watched
    @issues = current_user.watched_issues.currently_viewable_by(current_user).newest.page(params[:page]).per(8)
    render :show
  end

  def settings
  end

  def edit
  end

  def update
    @onboarding = !@user.onboarded?

    @user.assign_attributes(user_attributes)
    if @user.save(context: @onboarding ? :onboarding : :update)
      path = @user.onboarded_previously_changed? ? root_path : edit_profile_path
      redirect_to path, notice: "Zmeny profilu boli uložené."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_attributes
    params.require(:user).permit(:name, :anonymous, :municipality_id, :email_notifiable, :birth_year, :terms_of_service, :newsletter_accepted, :gdpr_stats_accepted, :onboarded)
  end

  def ensure_citizen
    if @user.responsible_subject
      redirect_to profile_path, alert: "Túto akciu nemôžete vykonať."
    end
  end
end
