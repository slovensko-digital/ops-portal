module Import
  class ImportStreetsJob < ApplicationJob
    include ImportHelper

    def perform(municipality:, batch_size: 100)
      0.step do |offset|
        records_array = ImportHelper.with_another_db(ActiveRecord::Base.configurations.configs_for(env_name: 'odkaz_pre_starostu').first) do
          ActiveRecord::Base.connection.exec_query("SELECT * FROM ulice where mesto = #{municipality.id} LIMIT #{batch_size} OFFSET #{offset * batch_size}")
        end

        records_array.each do |record|
          Street.find_or_create_by(
            id: record['id'],
            latitude: record['geo_y'],
            longitude: record['geo_x'],
            name: record['nazov'],
            place_identifier: record['place_id'],
            tested: record['tested'],
            municipality: municipality,
            municipality_district_id: record['mestska_cast'].nonzero? || nil
          )
        end

        break if records_array.count < batch_size
      end
    end
  end
end
