class IssueLikesController < ApplicationController
  include IssueScoped

  def create
    @issue.likes.find_or_initialize_by(user: current_user).save

    render partial: "button"
  end

  def destroy
    @issue.likes.where(user: current_user).destroy_all

    render partial: "button"
  end
end
