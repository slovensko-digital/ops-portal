class Issues::Drafts::DetailsController < ApplicationController
  include Issues::DraftScoped

  def show
  end

  def update
    if @draft.update_with_context(details_params, :details_step)
      Issues::Draft::GenerateChecksJob.perform_later(@draft)
      redirect_to issues_draft_summary_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def details_params
    params.expect(issues_draft: [ :title, :description ])
  end
end
