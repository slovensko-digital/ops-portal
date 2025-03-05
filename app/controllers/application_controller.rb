class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_user

  private

  def set_user
    # TODO: choose real user
    @user = User.find_or_create_by(
      email: ENV.fetch("DEFAULT_USER_EMAIL"),
      zammad_identifier: ENV.fetch("DEFAULT_USER_ZAMMAD_IDENTIFIER"),
      firstname: ENV.fetch("DEFAULT_USER_FIRSTNAME"),
      lastname: ENV.fetch("DEFAULT_USER_LASTNAME")
    )
  end
end
