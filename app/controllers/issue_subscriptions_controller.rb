class IssueSubscriptionsController < ApplicationController
  include IssueScoped

  def create
    current_user.issue_subscriptions.create(issue: @issue)

    render partial: "button"
  end

  def destroy
    current_user.issue_subscriptions.where(issue: @issue).destroy_all

    render partial: "button"
  end
end
