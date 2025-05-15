module Issues::ActivityScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_activity
  end

  private

  def set_activity
    @activity = Issues::Activity.find(params[:activity_id])
  end
end
