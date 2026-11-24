module SearchEngine
  # Values of the ?lokalita[]= search param: "Bratislava" is a municipality and
  # "Bratislava-Petržalka" one of its districts.
  #
  # Names can contain "-" themselves (the municipality "Súľov-Hradná", the
  # district "Trenčín - Juh"), so a value is never split blindly: it is matched
  # against the real municipality and district names. An exact municipality name
  # wins over a municipality-district pair.
  #
  # Old links used " - " as the separator ("Bratislava - Petržalka"); they still
  # match and come out in the current form.
  class Lokalita
    SEPARATOR = "-"
    LEGACY_SEPARATOR = " - "

    def self.value(municipality_name, district_name = nil)
      return municipality_name if district_name.blank?

      "#{municipality_name}#{SEPARATOR}#{district_name}"
    end

    def initialize(values)
      @values = Array(values).select { _1.is_a?(String) }.map(&:strip).reject(&:blank?).uniq
    end

    def municipalities
      @municipalities ||= Municipality.active.where(name: @values).to_a
    end

    # Districts are looked up only for values that are not a municipality name.
    def districts
      @districts ||= district_by_value.values.uniq
    end

    # The values in the current form; values that match nothing stay as they are.
    def canonical
      @values.map do |value|
        district = district_by_value[value]
        district ? self.class.value(district.municipality.name, district.name) : value
      end.uniq
    end

    # Chip label: a district shows only its own name, anything else the value itself.
    # Takes the value in either form.
    def label(value)
      district = district_by_value[value] ||
        districts.find { self.class.value(_1.municipality.name, _1.name) == value }

      district&.name || value
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
            [ SEPARATOR, LEGACY_SEPARATOR ].each do |separator|
              value = "#{district.municipality.name}#{separator}#{district.name}"
              by_value[value] ||= district if rest.include?(value)
            end
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
