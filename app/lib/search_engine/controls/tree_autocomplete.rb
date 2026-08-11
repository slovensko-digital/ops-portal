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
    end
  end
end
