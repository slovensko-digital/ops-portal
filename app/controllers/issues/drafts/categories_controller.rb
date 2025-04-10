class Issues::Drafts::CategoriesController < ApplicationController
  include Issues::DraftScoped

  def show
    @categories = ::Issues::Category.non_legacy.all
  end

  def update
    @draft.category = ::Issues::Category.find(params[:category_id])
    @draft.subcategory = @draft.subtype = nil # reset
    if @draft.save
      redirect_to issues_draft_subcategory_path(@draft)
    else
      render :show, status: :unprocessable_entity
    end
  end
end
