module SearchEngine
  module Controls
    # A two-level multi-select: parents with their children. items gives the
    # hierarchy, [{ label:, value:, children: [{ label:, value: }] }], and the
    # control works out what each click selects, storing as few values as it can:
    # - a selected parent stands for all its children, only the parent is stored;
    # - unselecting one of those children stores its siblings instead, so the
    #   parent becomes partial;
    # - selecting the last missing child stores the parent again.
    # Values are compared exactly, so a value that only looks like a child of
    # another parent ("Súľov-Hradná" next to "Súľov") is left alone.
    class TreeAutocomplete < Dropdown
      TreeItem = Struct.new(:label, :value, :selected, :partial, :level, :add_params, :remove_params, keyword_init: true) do
        def selected?
          selected
        end

        def partial?
          partial
        end
      end

      def initialize(**args)
        super(**args, multiple: true, sort: false)
      end

      def build_items(results, items)
        values = Array(results.search_params[@param_name])
        tree = resolve_items(results, items)
        position = tree.flat_map { |parent| [ parent[:value], *(parent[:children] || []).map { _1[:value] } ] }.each_with_index.to_h

        tree.flat_map do |parent|
          Group.new(parent, values).items.map do |item|
            TreeItem.new(
              **item,
              add_params: results.search_params.merge(@param_name => in_tree_order(item[:add_params], position)),
              remove_params: results.search_params.merge(@param_name => in_tree_order(item[:remove_params], position))
            )
          end
        end
      end

      # One parent and its children within the current values.
      class Group
        def initialize(parent, values)
          @parent = parent
          @children = parent[:children] || []
          child_values = @children.map { _1[:value] }

          @whole = values.include?(parent[:value])
          @chosen = @whole ? child_values : values & child_values
          @others = values - [ parent[:value] ] - child_values
        end

        def items
          [ parent_item, *@children.map { child_item(_1) } ]
        end

        private

        def parent_item
          {
            label: @parent[:label],
            value: @parent[:value],
            level: 0,
            selected: @whole,
            partial: !@whole && @chosen.any?,
            add_params: @others + [ @parent[:value] ],
            remove_params: @others
          }
        end

        def child_item(child)
          value = child[:value]

          {
            label: child[:label],
            value: value,
            level: 1,
            selected: @chosen.include?(value),
            partial: false,
            add_params: @others + collapse(@chosen | [ value ]),
            remove_params: @others + collapse(@chosen - [ value ])
          }
        end

        def collapse(chosen)
          if chosen.size == @children.size
            [ @parent[:value] ]
          else
            chosen
          end
        end
      end

      private

      # One URL per selection: values follow the tree, values outside it go last.
      def in_tree_order(values, position)
        values.each_with_index.sort_by { |value, index| [ position.fetch(value, position.size), index ] }.map(&:first)
      end
    end
  end
end
