module SearchEngine
  # Builds the municipality/district selection tree for the "Obec / Mestská časť"
  # search filter.
  #
  # Locations are plain strings: "Bratislava" selects a whole municipality,
  # "Bratislava - Petržalka" selects a single district and "-Bratislava - Petržalka"
  # excludes a district from its municipality.
  class LokalitaTree
    def initialize(locations)
      @locations = Array(locations).compact_blank
      @positives, @negatives = @locations.partition { !_1.start_with?("-") }
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
      others = @locations.reject { same_tree?(_1, municipality.name) }

      {
        label: municipality.name,
        value: municipality.name,
        level: 0,
        selected: @positives.include?(municipality.name),
        add_params: others + [ municipality.name ],
        remove_params: others
      }
    end

    def district_items(municipality)
      municipality_selected = @positives.include?(municipality.name)

      municipality.active_districts.map do |district|
        value = "#{municipality.name} - #{district.name}"
        selected = @positives.include?(value) ||
          (municipality_selected && !@negatives.include?("-#{value}"))

        district_item(district.name, value, selected, municipality_selected)
      end
    end

    def district_item(label, value, selected, municipality_selected)
      negative_value = "-#{value}"

      add_params, remove_params =
        if municipality_selected
          if @positives.include?(value)
            [ @locations - [ negative_value ],
              ((@locations - [ value ]) + [ negative_value ]).uniq ]
          else
            [ @locations - [ negative_value ],
              (@locations + [ negative_value ]).uniq ]
          end
        else
          [ (@locations + [ value ]).uniq,
            @locations - [ value ] ]
        end

      {
        label: label,
        value: value,
        level: 1,
        selected: selected,
        add_params: add_params,
        remove_params: remove_params
      }
    end

    def same_tree?(location, municipality_name)
      location == municipality_name ||
        location.start_with?("#{municipality_name} - ") ||
        location.start_with?("-#{municipality_name} - ")
    end
  end
end
