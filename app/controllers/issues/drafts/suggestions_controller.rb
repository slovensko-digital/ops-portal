class Issues::Drafts::SuggestionsController < ApplicationController
  include Issues::DraftScoped

  def show
  end

  def generate
    unless @draft.suggestions.any?
      Issues::Draft::GenerateSuggestionsJob.perform_now(@draft)
    end
  end

  def update
    @draft.assign_attributes(suggestions_params)
    @draft.load_suggestion

    if @draft.save(context: :suggestions_step)
      redirect_to issues_draft_details_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def suggestions_params
    params.expect(issues_draft: [ :picked_suggestion_index ])
  end
end
