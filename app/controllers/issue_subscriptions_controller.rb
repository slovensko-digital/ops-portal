class IssueSubscriptionsController < ApplicationController
  include IssueScoped
  before_action :require_user
  before_action :check_permissions

  def create
    current_user.subscribe_to(@issue)

    render partial: "button"
  end

  def destroy
    current_user.issue_subscriptions.where(issue: @issue).destroy_all

    render partial: "button"
  end

  def check_permissions
    render status: :unauthorized, body: nil unless current_user.can_view?(@issue)
  end
end
