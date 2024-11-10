class Issues::DraftsController < ApplicationController
  def new
    @draft = Issues::Draft.new
  end

  def create
    @draft = Issues::Draft.new(draft_params)
    if @draft.save(context: :photos)
      redirect_to issues_draft_suggestions_path(@draft)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @draft = Issues::Draft.find(params[:id])
  end

  def suggest
    @draft = Issues::Draft.find(params[:draft_id])

    @suggestions = @draft.calculate_suggestions
  end

  def submit
  end

  private

  def draft_params
    params.expect(issues_draft: [ :title, :body, photos: [] ])
  end
end
