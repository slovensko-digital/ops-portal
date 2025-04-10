class Issues::Drafts::SubtypesController < ApplicationController
  include Issues::DraftScoped

  def show
    @subtypes = Issues::Subtype.non_legacy.where(subcategory_id: @draft.subcategory_id).all
  end

  def update
    @draft.subtype = @draft.subcategory.subtypes.find(params[:subtype_id])
    if @draft.save
      redirect_to issues_draft_details_path(@draft)
    else
      @subtypes = Issues::Subtype.non_legacy.where(subcategory_id: @draft.subcategory_id).all
      render :show, status: :unprocessable_entity
    end
  end
end
