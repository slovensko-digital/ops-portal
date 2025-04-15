module Import
  class Addresses::ImportMunicipalitiesJob < ApplicationJob
    def perform(import_municipality_districts_job: ::Import::Addresses::ImportMunicipalityDistrictsJob, chain_import: false)
      ::Legacy::City.find_in_batches do |group|
        group.each do |legacy_record|
          Municipality.find_or_create_by!(
            legacy_id: legacy_record.id,
            active: legacy_record.status,
            alias: legacy_record.alias,
            category: legacy_record.city_type,
            email: legacy_record.email,
            handled_by: legacy_record.spravuje,
            has_municipality_districts: legacy_record.mestske_casti,
            languages: legacy_record.languages,
            latitude: legacy_record.map_y.presence,
            logo: legacy_record.logo,
            longitude: legacy_record.map_x.presence,
            municipality_type: legacy_record.typ,
            name: legacy_record.nazov,
            population: legacy_record.pocet_obyvatelov,
            sub: legacy_record.sub.presence,
            district: District.find_by(legacy_id: legacy_record.kraj)
          )
        end
      end

      import_municipality_districts_job.perform_later(chain_import: chain_import)
    end
  end
end
