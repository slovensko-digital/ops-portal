class Issues::ActivityVotesController < ApplicationController
  include Issues::ActivityScoped

  before_action :require_full_access_user

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
end
