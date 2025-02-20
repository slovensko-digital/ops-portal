module Import
  class Addresses::ImportStreetsJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name("ulice")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          Street.find_or_create_by!(
            legacy_id: legacy_record.id,
            latitude: legacy_record.geo_y,
            longitude: legacy_record.geo_x,
            name: legacy_record.nazov,
            place_identifier: legacy_record.place_id,
            tested: legacy_record.tested,
            municipality_district: MunicipalityDistrict.find_by(legacy_id: legacy_record.mestska_cast),
            municipality: Municipality.find_by(legacy_id: legacy_record.mesto)
          )
        end
      end
    end
  end
end
