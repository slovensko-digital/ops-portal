module Import
  class Addresses::ImportStreetsJob < ApplicationJob
    def perform
      Legacy::GenericModel.set_table_name('ulice')
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          Street.find_or_initialize_by(
            id: legacy_record.id,
            latitude: legacy_record.geo_y,
            longitude: legacy_record.geo_x,
            name: legacy_record.nazov,
            place_identifier: legacy_record.place_id,
            municipality_district_id: legacy_record.mestska_cast.nonzero? || nil,
            municipality_id: legacy_record.mesto
          ).tap do |street|
            street.tested = legacy_record.tested
            street.save!
          end
        end
      end
    end
  end
end
