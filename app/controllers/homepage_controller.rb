class HomepageController < ApplicationController
  before_action :ensure_user_onboarded

  def show
    @issues = Issue.order(created_at: :desc).joins(:state).where(state: { name: "Vyriešený" }).limit(4) # TODO show relevant on home page
    @news = Cms::Page.joins(:category).where(category: { name: "Aktuality" }).published.order(created_at: :desc).limit(4)
  end

  private

  def ensure_user_onboarded
    if current_user
      redirect_to edit_profile_path unless current_user.onboarded?
    end
  end
end
