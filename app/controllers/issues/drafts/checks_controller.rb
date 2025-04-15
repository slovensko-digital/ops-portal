class Issues::Drafts::ChecksController < ApplicationController
  include Issues::DraftScoped

  def create
    Issues::Draft::GenerateChecksJob.perform_now(@draft) if @draft.checks.nil?
    if @draft.valid?(:checks_step)
      @draft.confirm
      redirect_to thanks_issues_drafts_path
    else
      render :show, status: :unprocessable_entity
    end
  end
end
