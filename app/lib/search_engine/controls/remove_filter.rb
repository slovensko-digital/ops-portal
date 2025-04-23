module SearchEngine
  module Controls
    RemoveFilter = Struct.new(:label, :remove_filter_params) do
      include ActiveModel::Conversion
    end
  end
end
