class Issues::Drafts::DetailsController < ApplicationController
  include Issues::DraftScoped

  def show
    @draft.load_suggestion
  end

  def update
    if @draft.update_with_context(details_params, :details_step)
      redirect_to issues_draft_geo_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def details_params
    params.expect(issues_draft: [:title, :description, :author])
  end
end
