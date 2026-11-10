module SearchEngine
  module Controls
    class TreeAutocomplete < Dropdown
      TreeItem = Struct.new(:label, :value, :selected, :level, :add_params, :remove_params, keyword_init: true) do
        def selected?
          selected
        end
      end

      def initialize(sort: false, **args)
        super(**args, sort: sort)
      end

      # Removing a city chip also drops its district selections and exclusions,
      # otherwise ["Bratislava", "-Bratislava - Ružinov"] would degrade to an
      # exclusion-only list showing zero issues.
      def add_applied_filter(results)
        return unless results.search_params[@param_name].present?

        values = Array(results.search_params[@param_name])

        values.each do |value|
          remove_values =
            if value.is_a?(String) && !value.start_with?("-") && !value.include?(" - ")
              values.reject { same_tree?(_1, value) }
            else
              (values - [ value ]).uniq
            end

          results.applied_filters << RemoveFilter.new(
            label: @filter_label.respond_to?(:call) ? @filter_label.call(value) : @filter_label,
            remove_filter_params: results.search_params.merge(@param_name => remove_values),
          )
        end
      end

      def build_items(results, items)
        if items.respond_to?(:call)
          items = items.arity == 1 ? items.call(results.search_params) : items.call
        end

        values = Array(results.search_params[@param_name])

        items.map do |item_data|
          add_vals = item_data[:add_params] || (values + [ item_data[:value] ]).uniq
          remove_vals = item_data[:remove_params] || (values - [ item_data[:value] ]).uniq

          TreeItem.new(
            label: item_data[:label],
            value: item_data[:value],
            level: item_data[:level] || 0,
            selected: item_data[:selected],
            add_params: results.search_params.merge(@param_name => @multiple ? add_vals : item_data[:value]),
            remove_params: results.search_params.merge(@param_name => @multiple ? remove_vals : nil)
          )
        end
      end

      private

      def same_tree?(location, municipality_name)
        return false unless location.is_a?(String)

        location == municipality_name ||
          location.start_with?("#{municipality_name} - ") ||
          location.start_with?("-#{municipality_name} - ")
      end
    end
  end
end
