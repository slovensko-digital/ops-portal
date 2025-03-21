class AnnouncementsController < ApplicationController
  before_action :load_announcement, only: %i[show]
  before_action :ensure_url_up_to_date, only: %i[show]
  def index
    @announcements = Announcement.order(created_at: :desc).page(params[:page]).per(12)
  end

  def show
  end

  private

  def load_announcement
    @announcement = Announcement.find(params[:id])
  end

  def ensure_url_up_to_date
    if @announcement.to_param != params[:id]
      redirect_to announcement_path(@announcement), status: :moved_permanently
    end
  end
end
