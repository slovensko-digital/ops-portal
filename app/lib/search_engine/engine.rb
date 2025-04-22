module SearchEngine
  class Engine
    def initialize(filters:, per_page: nil)
      @filters = filters
      @per_page = per_page
    end

    def search(scope, params)
      @filters.each do |filter|
        scope = filter.apply(scope, params)
      end

      scope = scope.page(params[:page])
      scope = scope.per(@per_page) if @per_page

      build_results(scope, params)
    end

    def stats(scope, params)
      @filters.each do |filter|
        scope = filter.apply(scope, params)
      end

      build_stats(scope, params)
    end

    private

    def build_results(scope, params)
      results = Results.new
      permitted_params = @filters.each_with_object([]) do |filter, p|
        filter.add_permitted_params(p)
      end
      permitted_params << "tab"
      results.search_params = params.permit(*permitted_params)
      results.hits = scope
      @filters.each do |filter|
        filter.add_applied_filter(results)
      end

      @filters.each do |filter|
        filter.add_visible_filter(results)
      end

      results
    end

    def build_stats(scope, params)
      results = Results.new
      permitted_params = @filters.each_with_object([]) do |filter, p|
        filter.add_permitted_params(p)
      end
      permitted_params << "tab"
      results.search_params = params.permit(*permitted_params)
      scope = scope.reorder("")
      results.stats = {
        by_state: scope.group("state").order("count_all DESC").async_count,
        by_category: scope.group("category").order("count_all DESC").async_count,
        by_responsible_subject: scope.group("responsible_subject").order("count_all DESC").async_count,
      }

      @filters.each do |filter|
        filter.add_applied_filter(results)
      end

      @filters.each do |filter|
        filter.add_visible_filter(results)
      end

      results
    end
  end
end
