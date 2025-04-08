class Triage::UpdatePortalIssueFromTriageJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client)
    ticket = triage_zammad_client.get_ticket(ticket_id)
    raise "Ticket not found" unless ticket

    issue = Issue.find_by(triage_external_id: ticket_id)
    raise "Issue not found" unless issue

    municipality = Municipality.find_by(name: ticket[:address_municipality].split("::").first)
    municipality_district = municipality&.municipality_districts&.find_by(name: ticket[:address_municipality].split("::").last)

    category = Issues::Category.find_by(name: ticket[:category])
    subcategory = category&.subcategories&.find_by(name: ticket[:subcategory])
    subtype = subcategory&.subtypes&.find_by(name: ticket[:subtype])

    issue.update!(
      title: ticket[:title],
      municipality: municipality,
      municipality_district: municipality_district,
      address_state: ticket[:address_state],
      address_county: ticket[:address_county],
      address_postcode: ticket[:address_postcode],
      address_street: ticket[:address_street],
      address_house_number: ticket[:address_house_number],
      latitude: ticket[:address_lat],
      longitude: ticket[:address_lon],
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      state: Issues::State.find_by(name: ticket[:state]),
      responsible_subject: ticket[:responsible_subject],
    )
  end
end
