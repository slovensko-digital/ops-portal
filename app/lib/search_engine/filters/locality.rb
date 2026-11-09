module SearchEngine
  module Filters
    class Locality
      def initialize(locations)
        @locations = Array(locations).filter_map do |location|
          next unless location.is_a?(String)

          stripped = location.strip
          stripped.presence
        end
      end

      def apply(scope)
        return scope if @locations.empty?

        positives, negatives = @locations.partition { !_1.start_with?("-") }
        # No positive selection (only exclusions) -> nothing to filter by.
        return scope if positives.empty?

        negatives = negatives.map { _1.delete_prefix("-").strip }.reject(&:empty?)

        municipalities, districts = positives.partition { !_1.include?(" - ") }

        municipality_ids = Municipality.active
                                       .where(name: municipalities)
                                       .pluck(:id)

        district_ids = find_district_ids(districts)
        excluded_district_ids = find_district_ids(
          negatives.select { |negative| municipalities.include?(municipality_name_from(negative)) }
        )

        conditions = []

        if municipality_ids.any?
          condition = scope.where(municipality_id: municipality_ids)

          if excluded_district_ids.any?
            without_district = condition.where(municipality_district_id: nil)
            outside_excluded = condition.where.not(municipality_district_id: excluded_district_ids)
            condition = without_district.or(outside_excluded)
          end

          conditions << condition
        end

        conditions << scope.where(municipality_district_id: district_ids) if district_ids.any?

        conditions.reduce(:or) || scope.none
      end

      private

      def municipality_name_from(location)
        location.split(" - ", 2).first&.strip
      end

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
