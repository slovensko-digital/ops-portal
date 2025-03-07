class Import::InitialImportJob < ApplicationJob
  def perform
    # Do not run jobs in parallel (with perform_later) - Legacy::GenericModel problem with connection to various legacy tables
    Import::Addresses::ImportDistrictsJob.perform_later(chain_import: true)

    Import::Issues::ImportCategoriesJob.perform_later
    Import::Issues::ImportStatesJob.perform_later

    Import::ResponsibleSubjects::ImportUserRolesJob.perform_later(chain_import: true)

    Import::ImportUsersJob.perform_later
    Import::ImportAgentsJob.perform_later
  end
end
