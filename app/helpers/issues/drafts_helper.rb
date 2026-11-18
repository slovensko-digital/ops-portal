module Issues::DraftsHelper
  def unfinished_step_issues_draft_path(draft)
    case draft.first_unfinished_step
    when :photos then edit_issues_draft_path(draft)
    when :geo then issues_draft_geo_path(draft)
    when :suggestions then issues_draft_suggestions_path(draft)
    when :category then issues_draft_category_path(draft, next: unfinished_category_next(draft))
    when :details then issues_draft_details_path(draft, next: :summary)
    else issues_draft_summary_path(draft)
    end
  end

  private

  # without a title the category steps continue to details instead of back to the summary
  def unfinished_category_next(draft)
    :summary if draft.title.present?
  end
end
