class ImportJob < ApplicationJob
  def perform
    ImportAddressDataJob.perform_later
    ImportIssueCategoriesJob.perform_later
    ImportResponsibleSubjectsDataJob.perform_later
  end
end
