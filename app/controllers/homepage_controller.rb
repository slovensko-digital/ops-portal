class HomepageController < ApplicationController
  def show
    @issues = Issue.order(reported_at: :desc).limit(4) # TODO show relevant on home page
    @news = Cms::Page.joins(:category).where(category: { name: "Aktuality" }).published.order(created_at: :desc).limit(4)
  end
end
