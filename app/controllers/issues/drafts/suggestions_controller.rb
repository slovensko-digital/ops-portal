class Issues::Drafts::SuggestionsController < ApplicationController
  before_action :set_draft

  def show
  end

  def suggest
    @draft.calculate_suggestions # TODO unless @draft.suggestions.any?
    @draft.save!
  end

  def update
    if @draft.update_with_context(suggestions_params, :suggestions_step)
      redirect_to issues_draft_details_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_draft
    @draft = Issues::Draft.find(params[:draft_id])
  end

  def suggestions_params
    params.expect(issues_draft: [:picked_suggestion_index])
  end
end
