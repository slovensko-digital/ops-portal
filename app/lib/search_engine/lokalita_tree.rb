module SearchEngine
  # Builds the municipality/district selection tree for the "Obec / Mestská časť"
  # search filter.
  #
  # Locations are plain strings: "Bratislava" selects a whole municipality and
  # "Bratislava - Petržalka" a single district. The selection follows the profile
  # picker:
  # - a selected municipality shows all its districts as selected, but only the
  #   municipality is in the params;
  # - unselecting one of those districts replaces the municipality with its other
  #   districts, so the municipality becomes partial;
  # - selecting the last missing district replaces the districts with the
  #   municipality again.
  class LokalitaTree
    def initialize(locations)
      @locations = Array(locations)
        .select { _1.is_a?(String) }
        .map(&:strip)
        .reject { _1.blank? || _1.start_with?("-") }
    end

    def items
      municipalities.flat_map do |municipality|
        [ parent_item(municipality), *district_items(municipality) ]
      end
    end

    private

    def municipalities
      Municipality.active
                  .where(active_on_old_portal: false)
                  .includes(:active_districts)
                  .order(Arel.sql("name COLLATE unicode"))
    end

    def parent_item(municipality)
      others = outside(municipality)
      district_values = municipality.active_districts.map { district_value(municipality, _1) }

      {
        label: municipality.name,
        value: municipality.name,
        level: 0,
        selected: @locations.include?(municipality.name),
        partial: !@locations.include?(municipality.name) && district_values.intersect?(@locations),
        add_params: others + [ municipality.name ],
        remove_params: others
      }
    end

    def district_items(municipality)
      municipality_selected = @locations.include?(municipality.name)
      district_values = municipality.active_districts.map { district_value(municipality, _1) }
      others = outside(municipality)

      municipality.active_districts.zip(district_values).map do |district, value|
        siblings = district_values - [ value ]
        selected = municipality_selected || @locations.include?(value)

        add_params =
          if (siblings - @locations).empty?
            others + [ municipality.name ]
          else
            (@locations + [ value ]).uniq
          end

        remove_params = municipality_selected ? others + siblings : @locations - [ value ]

        {
          label: district.name,
          value: value,
          level: 1,
          selected: selected,
          partial: false,
          add_params: add_params,
          remove_params: remove_params
        }
      end
    end

    def district_value(municipality, district)
      "#{municipality.name} - #{district.name}"
    end

    # The selection without this municipality and any of its districts.
    def outside(municipality)
      @locations.reject do |location|
        location == municipality.name || location.start_with?("#{municipality.name} - ")
      end
    end
  end
end
