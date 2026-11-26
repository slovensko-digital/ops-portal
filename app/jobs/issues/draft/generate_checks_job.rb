class Issues::Draft::GenerateChecksJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(draft)
    draft.checks = Ai::IssueChecks.generate(
      title: draft.title,
      description: draft.description,
      address: [ draft.address_city, draft.address_municipality, draft.address_street ].compact.join(", ")
    )
    draft.save!
  end
end
