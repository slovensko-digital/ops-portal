class HomepageController < ApplicationController
  before_action :ensure_user_onboarded

  def show
    @issues = Issue
      .relevant_for(current_user)
      .where(state: { key: "resolved" })
      .newest
      .joins(:state)
      .limit(4)
    @news = Cms::Page.joins(:category).where(category: { name: "Aktuality" }).published.order(created_at: :desc).limit(4)
  end
end
