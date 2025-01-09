module Import
  class ImportResponsibleSubjectsDataJob < ApplicationJob
    def perform
      ImportResponsibleSubjectTypesJob.perform_later(chain_import: true)
    end
  end
end
