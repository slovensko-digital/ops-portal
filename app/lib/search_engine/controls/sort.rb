module SearchEngine
  module Controls
    class Sort
      include ActiveModel::Conversion
      attr_reader :name, :label

      Item = Struct.new(:control, :params, :selected, keyword_init: true) do
        delegate :to_partial_path, to: :control
      end

      def initialize(
        name:, label:, order:,
        visible_if: ->(_) { true },
        apply_if: nil
      )
        @name = name
        @label = label
        @order = order
        @visible_if = visible_if
        @apply_if = apply_if || ->(params) { params[:sort] == @name.to_s }
      end

      def apply(scope, params)
        scope = @order.call(scope, params) if @apply_if.call(params)

        scope
      end

      def add_sort(results)
        results.sorts << Item.new(
          control: self,
          params: results.search_params.merge(sort: @name),
          selected: @apply_if.call(results.search_params)
        ) if @visible_if.call(results.search_params)
      end
    end
  end
end
