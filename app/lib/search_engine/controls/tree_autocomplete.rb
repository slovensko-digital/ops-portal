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

      def build_items(results, items)
        if items.respond_to?(:call)
          items = items.arity == 1 ? items.call(results.search_params) : items.call
        end

        values = Array(results.search_params[@param_name])

        out = items.map do |item_data|
          if item_data.is_a?(Hash)
            label = item_data[:label]
            val = item_data[:value] || label
            level = item_data[:level] || 0
            is_selected = item_data.key?(:selected) ? item_data[:selected] : values.include?(val)
          else
            label = item_data.to_s
            val = item_data.to_s
            level = 0
            is_selected = values.include?(val)
          end

          TreeItem.new(
            label: label,
            value: val,
            level: level,
            selected: is_selected,
            add_params: results.search_params.merge(@param_name => @multiple ? (values + [ val ]).uniq : val),
            remove_params: results.search_params.merge(@param_name => @multiple ? (values - [ val ]).uniq : nil),
            )
        end
        out
      end
    end
  end
end
