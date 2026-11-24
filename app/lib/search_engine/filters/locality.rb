module SearchEngine
  module Filters
    class Locality
      def initialize(locations)
        @locations = Array(locations)
          .select { _1.is_a?(String) }
          .map(&:strip)
          .reject(&:blank?)
      end

      def apply(scope)
        return scope if @locations.empty?

        lokalita = SearchEngine::Lokalita.new(@locations)
        municipality_ids = lokalita.municipalities.map(&:id)
        district_ids = lokalita.districts.map(&:id)

        conditions = []
        conditions << scope.where(municipality_id: municipality_ids) if municipality_ids.any?
        conditions << scope.where(municipality_district_id: district_ids) if district_ids.any?

        conditions.reduce(:or) || scope.none
      end
    end
  end
end
