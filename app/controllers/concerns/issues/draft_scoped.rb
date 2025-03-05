module Issues::DraftScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_draft
    before_action :set_user
  end

  private

  def set_draft
    @draft = Issues::Draft.find(params[:draft_id])
  end

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
