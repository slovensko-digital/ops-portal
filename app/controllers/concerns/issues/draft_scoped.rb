module Issues::DraftScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_draft
  end

  private

  def set_draft
    @draft = current_user.issues_drafts.find(params[:draft_id])
  end
end
