class HomepageController < ApplicationController
  def show
    @issues = Issue.limit(4) # TODO show relevant on home page
    @news = [] # TODO
  end
end
