module SearchEngine
  # The localities (municipalities and districts) selected in one search, as the
  # values of the ?lokalita[]= param: "Bratislava" is a municipality and
  # "Bratislava-Petržalka" one of its districts.
  #
  # Names can contain "-" themselves (the municipality "Súľov-Hradná", the
  # district "Trenčín - Juh"), so a value is never split blindly: it is matched
  # against the real municipality and district names. An exact municipality name
  # wins over a municipality-district pair.
  class LocalitySelection
    SEPARATOR = "-"

    # The value of a Municipality or MunicipalityDistrict. Anything else is
    # taken to be a value already.
    def self.param(place)
      case place
      when MunicipalityDistrict then param_from_names(place.municipality.name, place.name)
      when Municipality then param_from_names(place.name)
      else place
      end
    end

    def self.param_from_names(municipality_name, district_name = nil)
      return municipality_name if district_name.blank?

      "#{municipality_name}#{SEPARATOR}#{district_name}"
    end

    def initialize(values)
      @values = Array(values).select { _1.is_a?(String) }.map(&:strip).reject(&:blank?).uniq
    end

    def municipalities
      @municipalities ||= Municipality.active.where(name: @values).to_a
    end

    def districts
      @districts ||= district_by_value.values.uniq
    end

    # Chip label: a district shows only its own name, anything else the value itself.
    def label(value)
      district_by_value[value]&.name || value
    end

    private

    def district_by_value
      @district_by_value ||= begin
        rest = @values - municipalities.map(&:name)
        prefixes = rest.flat_map { |value| municipality_prefixes(value) }.uniq

        if prefixes.empty?
          {}
        else
          MunicipalityDistrict.joins(:municipality)
                              .where(municipalities: { name: prefixes })
                              .includes(:municipality)
                              .each_with_object({}) do |district, by_value|
            value = self.class.param(district)
            by_value[value] = district if rest.include?(value)
          end
        end
      end
    end

    # Every text before a "-" could be the municipality: "Súľov-Hradná-Centrum"
    # gives "Súľov" and "Súľov-Hradná".
    def municipality_prefixes(value)
      value.enum_for(:scan, SEPARATOR).map { Regexp.last_match.begin(0) }.filter_map { value[0...it].strip.presence }
    end
  end
end
