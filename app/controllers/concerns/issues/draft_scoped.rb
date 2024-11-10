module Issues::DraftScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_draft
  end

  private

  def set_draft
    @draft = Issues::Draft.find(params[:draft_id])
  end
end