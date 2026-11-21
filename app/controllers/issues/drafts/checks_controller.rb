class Issues::Drafts::ChecksController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped
  before_action :redirect_unfinished_draft_to_summary, only: [ :create, :confirm ]

  def show
    @draft.valid?(:checks_step)
  end

  def confirm
    if @draft.confirmable?
      @draft.confirm

      redirect_to thanks_issues_drafts_path
    end
  end

  def create
    Issues::Draft::GenerateChecksJob.perform_now(@draft) if @draft.checks.nil?
    Issues::Draft::FetchAddressDetailsJob.perform_now(@draft) if @draft.address_data.nil?
    if @draft.valid?(:checks_step)
      @draft.confirm
      redirect_to thanks_issues_drafts_path
    else
      redirect_to action: :show
    end
  end

  private

  def redirect_unfinished_draft_to_summary
    redirect_to issues_draft_summary_path(@draft) unless @draft.complete?
  end
end
