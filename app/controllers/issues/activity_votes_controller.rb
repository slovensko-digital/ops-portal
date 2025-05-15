class Issues::ActivityVotesController < ApplicationController
  include Issues::ActivityScoped

  before_action :require_full_access_user
  before_action :check_permissions

  def create
    @activity.votes.find_or_initialize_by(voter: current_user).tap do |vote|
      vote.vote = params[:vote]
      vote.save
    end

    render partial: "buttons", locals: { activity: @activity }
  end

  def destroy
    @activity.votes.where(voter: current_user, vote: params[:vote]).destroy_all

    render partial: "buttons", locals: { activity: @activity }
  end

  def check_permissions
    render status: :unauthorized, body: nil unless current_user.can_view?(@activity.issue)
  end
end
