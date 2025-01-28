module Import
  class Addresses::ImportMunicipalitiesJob < ApplicationJob
    def perform(import_municipality_districts_job: ::Import::Addresses::ImportMunicipalityDistrictsJob, chain_import: false)
      Legacy::GenericModel.set_table_name("mesta")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          Municipality.find_or_initialize_by(
            id: legacy_record.id,
            alias: legacy_record.alias,
            category: legacy_record.city_type,
            email: legacy_record.email,
            has_municipality_districts: legacy_record.mestske_casti,
            languages: legacy_record.languages,
            latitude: legacy_record.map_y.presence || nil,
            longitude: legacy_record.map_x.presence || nil,
            municipality_type: legacy_record.typ,
            name: legacy_record.nazov,
            sub: legacy_record.sub,
            district_id: legacy_record.kraj || nil
          ).tap do |municipality|
            municipality.active =  legacy_record.status
            municipality.handled_by = legacy_record.spravuje
            municipality.population = legacy_record.pocet_obyvatelov
            municipality.logo = legacy_record.logo
            municipality.save!
          end
        end
      end

      import_municipality_districts_job.perform_later(chain_import: chain_import)
    end
  end
end
