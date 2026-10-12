# Filters boundaries shown on the admin boundaries map. A list left out (nil) keeps all of its options,
# an empty list keeps none.
class MunicipalityBoundary::AdminFilter
  MATCHED = %w[matched unmatched].freeze
  ACTIVE = %w[true false].freeze

  attr_reader :kinds, :matched, :active, :municipality_ids, :municipality_district_ids

  def initialize(kinds: nil, matched: nil, active: nil, municipality_ids: [], municipality_district_ids: [], bbox: nil)
    @kinds = options(kinds, MunicipalityBoundary::KINDS)
    @matched = options(matched, MATCHED)
    @active = options(active, ACTIVE)
    @municipality_ids = Array(municipality_ids).compact_blank.map(&:to_i)
    @municipality_district_ids = Array(municipality_district_ids).compact_blank.map(&:to_i)
    @bbox = bbox.to_s.split(",").map(&:to_f) if bbox.present?
  end

  # The active flag only applies to matched boundaries, unmatched ones have no municipality to check.
  def boundaries
    scopes = []
    scopes << by_active(base.matched) if matched.include?("matched")
    scopes << base.unmatched if matched.include?("unmatched")
    scopes.reduce(:or) || MunicipalityBoundary.none
  end

  private

  def options(values, all)
    values.nil? ? all : Array(values).compact_blank & all
  end

  def base
    return MunicipalityBoundary.none if kinds.empty?

    scope = MunicipalityBoundary.left_joins(:municipality, :municipality_district)
    scope = scope.where("boundary && ST_MakeEnvelope(?, ?, ?, ?, 4326)", *@bbox) if @bbox
    kinds.map { by_selection(scope.where(boundary_kind: it), it) }.reduce(:or)
  end

  # district boundaries are filtered by the active flag of the municipality they belong to
  def by_active(scope)
    return scope if (ACTIVE - active).empty?

    scope.where(municipalities: { active: active.map { it == "true" } })
  end

  # A selected municipality shows its own boundary and all of its districts. Selecting some of its districts
  # narrows the district layer down to those, while the municipality boundary stays visible.
  def by_selection(scope, kind)
    return scope if municipality_ids.empty? && municipality_district_ids.empty?

    municipality_ids_of_districts = MunicipalityDistrict.where(id: municipality_district_ids).distinct.pluck(:municipality_id)

    if kind == "district"
      scope.where(municipality_district_id: municipality_district_ids)
        .or(scope.where(municipality_id: municipality_ids - municipality_ids_of_districts))
    else
      scope.where(municipality_id: municipality_ids | municipality_ids_of_districts)
    end
  end
end
