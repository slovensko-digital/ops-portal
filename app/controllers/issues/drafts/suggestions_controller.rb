class Issues::Drafts::SuggestionsController < ApplicationController
  include Issues::DraftScoped

  def show
    Issues::Draft::GenerateSuggestionsJob.perform_now(@draft) unless @draft.suggestions
  end

  def update
    if @draft.pick_suggestion(suggestions_params)
      Issues::Draft::GenerateChecksJob.perform_now(@draft)
      redirect_to issues_draft_summary_path(@draft) and return if params[:next] == "summary" || params[:issues_draft][:picked_suggestion_index] != "-1"

      redirect_to issues_draft_category_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def suggestions_params
    params.expect(issues_draft: [ :picked_suggestion_index ])
  end
end
