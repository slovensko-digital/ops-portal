module SearchEngine
  module Filters
    class Locality < SearchEngine::Controls::SearchField
      def initialize(locations)
        @locations = Array(locations).compact_blank
      end

      def apply(scope)
        return scope if @locations.empty?

        positives, negatives = @locations.partition { !_1.start_with?("-") }
        negatives = negatives.map { _1.delete_prefix("-") }

        municipalities, districts = positives.partition { !_1.include?(" - ") }

        municipality_ids = Municipality.active
                                       .where(name: municipalities)
                                       .pluck(:id)

        district_ids = find_district_ids(districts)
        excluded_district_ids = find_district_ids(negatives)

        conditions = []

        if municipality_ids.any?
          condition = scope.where(municipality_id: municipality_ids)
          condition = condition.where.not(
            municipality_district_id: excluded_district_ids
          ) if excluded_district_ids.any?

          conditions << condition
        end

        conditions << scope.where(municipality_district_id: district_ids) if district_ids.any?

        conditions.reduce(:or) || scope.none
      end

      private

      def find_district_ids(locations)
        locations
          .map { _1.split(" - ", 2) }
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
