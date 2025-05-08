module Import
  class Addresses::ImportMunicipalityDistrictsJob < ApplicationJob
    def perform(import_streets_job: ::Import::Addresses::ImportStreetsJob, chain_import: false)
      Legacy::CityDistrict.find_in_batches do |group|
        group.each do |legacy_record|
          MunicipalityDistrict.find_or_create_by!(
            legacy_id: legacy_record.id,
            aliases: [ legacy_record.alias ].compact,
            description: legacy_record.popis.presence,
            genitiv: legacy_record.genitiv,
            logo: legacy_record.logo,
            lokal: legacy_record.lokal,
            name: legacy_record.nazov.strip,
            municipality: Municipality.find_by(legacy_id: legacy_record.mesto),
          )
        end
      end

      import_streets_job.perform_later if chain_import
    end
  end
end
