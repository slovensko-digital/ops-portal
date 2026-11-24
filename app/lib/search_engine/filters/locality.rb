module SearchEngine
  module Filters
    class Locality
      # Old URLs may still carry "-Obec - Časť" exclusions; they are ignored.
      def initialize(locations)
        @locations = Array(locations)
          .select { _1.is_a?(String) }
          .map(&:strip)
          .reject { _1.blank? || _1.start_with?("-") }
      end

      def apply(scope)
        return scope if @locations.empty?

        municipalities, districts = @locations.partition { !_1.include?(" - ") }

        municipality_ids = Municipality.active.where(name: municipalities).pluck(:id)
        district_ids = find_district_ids(districts)

        conditions = []
        conditions << scope.where(municipality_id: municipality_ids) if municipality_ids.any?
        conditions << scope.where(municipality_district_id: district_ids) if district_ids.any?

        conditions.reduce(:or) || scope.none
      end

      private

      def find_district_ids(locations)
        locations
          .filter_map do |location|
            municipality, district = location.split(" - ", 2).map(&:strip)
            next if municipality.blank? || district.blank?

            [ municipality, district ]
          end
          .reduce(MunicipalityDistrict.none) do |query, (municipality, district)|
            query.or(
              MunicipalityDistrict
                .joins(:municipality)
                .where(
                  municipalities: { name: municipality },
                  name: district
                )
            )
          end
          .pluck(:id)
      end
    end
  end
end
