class IssueSubscriptionsController < ApplicationController
  include IssueScoped
  before_action :require_user

  def create
    current_user.subscribe_to(@issue)

    render partial: "button"
  end

  def destroy
    current_user.issue_subscriptions.where(issue: @issue).destroy_all

    render partial: "button"
  end
end
