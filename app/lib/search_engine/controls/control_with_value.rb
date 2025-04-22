# frozen_string_literal: true

module SearchEngine
  module Controls
    class ControlWithValue
      attr_reader :control, :value

      def initialize(control:, value: )
        @control = control
        @value = value
      end

      def to_partial_path
        @control.to_partial_path
      end
    end
  end
end
