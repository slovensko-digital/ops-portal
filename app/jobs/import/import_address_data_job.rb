module Import
  class ImportAddressDataJob < ApplicationJob
    def perform
      ImportDistrictsJob.perform_later(chain_import: true)
    end
  end
end
