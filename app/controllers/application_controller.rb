class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  http_basic_authenticate_with name: "ops", password: "odkazprestarostu" unless Rails.env.development? || Rails.env.test?

  before_action :current_user

  private

  def current_user
    rodauth.rails_account # `rodauth.rails_account` surprisingly sets value for registration and password reset
  end
  helper_method :current_user

  def logged_in?
    # `rodauth.logged_in?` checks only session entry
    # `rodauth.rails_account` surprisingly sets value for registration and password reset
    rodauth.logged_in? && current_user.present?
  end
  helper_method :logged_in?

  def require_user
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page"
      redirect_to rodauth.login_path
    end
  end
end
