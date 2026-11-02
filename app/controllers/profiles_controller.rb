class ProfilesController < ApplicationController
  before_action :require_user, except: [ :please_create ]
  before_action :set_user, except: [ :please_create, :please_verify ]
  before_action :set_cms_pages, only: :show, if: -> { current_user.responsible_subject }

  before_action :ensure_citizen, only: [ :edit, :update, :settings, :watched_issues ]

  def please_create
  end

  def please_verify
  end

  def please_wait
  end

  def show
    @tab = :my
    @issues, @issue_pagination = PageRange.paginate(current_user.issues.newest, params[:page], ISSUES_PER_PAGE)
  end

  def watched_issues
    @tab = :watched
    scope = current_user.watched_issues.currently_viewable_by(current_user).newest
    @issues, @issue_pagination = PageRange.paginate(scope, params[:page], ISSUES_PER_PAGE)
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

  def set_cms_pages
    return unless ENV["CMS_ROOT_CATEGORY_ID"].present?

    root_category = Cms::Category.find_by(id: ENV["CMS_ROOT_CATEGORY_ID"])
    return unless root_category

    @startujeme_page = root_category.find_page_with_slug("startujeme-s-odkazom")
    @manual_page = root_category.find_page_with_slug("manual")
  end
end
