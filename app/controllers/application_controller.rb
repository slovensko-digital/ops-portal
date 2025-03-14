class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :current_user

  private

  def current_user
    rodauth.rails_account
  end
  helper_method :current_user

  def current_user?
    current_user.present?
  end
  helper_method :current_user?

  def require_login
    unless current_user?
      flash[:alert] = 'You must be logged in to access this page'
      redirect_to rodauth.login_path
    end
  end
end
