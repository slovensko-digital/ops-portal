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
end
