module SearchEngine
  class Results
    attr_accessor :hits, :stats, :applied_filters, :visible_filters, :search_params, :sorts

    def initialize
      @hits = []
      @applied_filters = []
      @visible_filters = []
      @sorts = []
      @search_params = {}
    end
  end
end
