class Import::InitialImportJob < ApplicationJob
  def perform
    Import::Addresses::ImportDistrictsJob.perform_later(chain_import: true)

    Import::Issues::ImportCategoriesJob.perform_later
    Import::Issues::ImportStatesJob.perform_later

    Import::ResponsibleSubjects::ImportUserRolesJob.perform_later(chain_import: true)

    Import::ImportUsersJob.perform_later
  end
end
