class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  http_basic_authenticate_with name: "ops", password: ENV["PORTAL_PASSWORD"] if !Rails.env.development? && !Rails.env.test? && ENV["PORTAL_PASSWORD"] != "0"

  before_action :check_for_maintenance_mode
  before_action :current_user

  private

  def current_user
    # `rodauth.rails_account` surprisingly sets value for registration and password reset
    rodauth.rails_account || AnonymousUser.new
  end

  helper_method :current_user

  def logged_in?
    # `rodauth.logged_in?` checks only session entry
    # `rodauth.rails_account` surprisingly sets value for registration and password reset
    rodauth.logged_in? && rodauth.rails_account
  end

  helper_method :logged_in?

  def require_user
    redirect_to_with_turbo please_create_profile_path unless logged_in?
  end

  def require_full_access_user
    require_user

    redirect_to_with_turbo please_verify_profile_path if logged_in? && !current_user.full_access?
  end

  def ensure_user_onboarded
    if logged_in?
      redirect_to edit_profile_path unless current_user.onboarded?
    end
  end

  def redirect_to_with_turbo(path)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.redirect(path) }
      format.html { redirect_to path }
    end
  end

  def check_for_maintenance_mode
    cookies.signed[:bypass] = {
      value: params[:bypass],
      expires: 1.day.from_now
    } if params[:bypass]
    return if cookies.signed[:bypass] == "1"

    render template: "errors/render_503", layout: false, status: 503 if ENV["MAINTENANCE"] == "1"
  end
end
