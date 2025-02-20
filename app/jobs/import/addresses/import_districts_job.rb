module Import
  class Addresses::ImportDistrictsJob < ApplicationJob
    def perform(import_municipalities_job: ::Import::Addresses::ImportMunicipalitiesJob, chain_import: false)
      Legacy::GenericModel.set_table_name("kraje")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          District.find_or_create_by!(
            legacy_id: legacy_record.id,
            name: legacy_record.nazov_kraju
          )
        end
      end

      import_municipalities_job.perform_later(chain_import: chain_import) if chain_import
    end
  end
end
