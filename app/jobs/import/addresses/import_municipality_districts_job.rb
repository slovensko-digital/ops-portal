module Import
  class Addresses::ImportMunicipalityDistrictsJob < ApplicationJob
    def perform(import_streets_job: ::Import::Addresses::ImportStreetsJob, chain_import: false)
      Legacy::GenericModel.set_table_name("mestske_casti")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          MunicipalityDistrict.find_or_initialize_by(
            id: legacy_record.id,
            alias: legacy_record.alias,
            genitiv: legacy_record.genitiv,
            lokal: legacy_record.lokal,
            name: legacy_record.nazov,
            municipality_id: legacy_record.mesto.nonzero? || nil,
          ).tap do |municipality_district|
            municipality_district.description = legacy_record.popis.presence
            municipality_district.logo = legacy_record.logo
            municipality_district.save!
          end
        end
      end

      import_streets_job.perform_later if chain_import
    end
  end
end
