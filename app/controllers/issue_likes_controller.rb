class IssueLikesController < ApplicationController
  include IssueScoped
  before_action :require_full_access_user
  before_action :check_permissions

  def create
    @issue.likes.find_or_initialize_by(user: current_user).save

    render partial: "button"
  end

  def destroy
    @issue.likes.where(user: current_user).destroy_all

    render partial: "button"
  end

  private
  def check_permissions
    render status: :unauthorized, body: nil unless current_user.can_view?(@issue)
  end
end
