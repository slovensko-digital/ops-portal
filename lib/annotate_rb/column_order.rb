# Loaded by annotaterb through `:require` in .annotaterb.yml.
#
# Overrides annotaterb's classified sort (id, columns, timestamps, foreign keys)
# with our order:
#   1. primary key(s)
#   2. foreign keys (*_id, plus polymorphic *_type), alphabetical
#   3. other columns, alphabetical
#   4. *_at columns, alphabetical, with created_at and updated_at last
module AnnotateRb
  module ColumnOrder
    TRAILING_TIMESTAMPS = %w[created_at updated_at].freeze

    private

    def classified_sort(cols, _grouped_polymorphic)
      primary_keys = Array(@klass.primary_key)
      col_names = cols.map(&:name)

      groups = cols.group_by do |col|
        name = col.name
        if primary_keys.include?(name) then :primary
        elsif name.end_with?("_id") then :foreign
        elsif name.end_with?("_type") && col_names.include?(name.delete_suffix("_type") + "_id") then :foreign
        elsif name.end_with?("_at") then :timestamp
        else :rest
        end
      end

      primary = (groups[:primary] || []).sort_by { |col| primary_keys.index(col.name) }
      foreign = (groups[:foreign] || []).sort_by(&:name)
      rest = (groups[:rest] || []).sort_by(&:name)
      timestamps = (groups[:timestamp] || []).sort_by do |col|
        [ TRAILING_TIMESTAMPS.index(col.name) || -1, col.name ]
      end

      primary + foreign + rest + timestamps
    end
  end
end

AnnotateRb::ModelAnnotator::ModelWrapper.prepend(AnnotateRb::ColumnOrder)
