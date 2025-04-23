module IssuesHelper
  def format_draft_address(draft)
    return "Nezistené" unless draft.address_data
    street = [ draft.address_street, draft.address_house_number ].compact.join(" ")
    [ street, draft.address_municipality, draft.address_city ].compact.join(", ")
  end

  def format_issue_address(draft)
    return "Nezistené" unless draft.address_municipality
    [ draft.address_street, draft.address_municipality, draft.address_city ].map(&:presence).compact.join(", ")
  end

  def search_issues_path(params = {})
    if @search_results
      issues_path(@search_results.search_params.merge(params))
    else
      issues_path(params)
    end
  end
end
