module SearchEngine
  class Engine
    def initialize(filters:, sorts: [], per_page: nil, default_permitted_params: [])
      @filters = filters
      @sorts = sorts
      @per_page = per_page
      @default_permitted_params = default_permitted_params
    end

    def search(scope, params)
      results = build_results_with_filters(params)
      search_params = results.search_params

      scope = apply_filters(scope, search_params)
      scope = apply_sort(scope, search_params)

      scope = scope.page(search_params[:page])
      scope = scope.per(@per_page) if @per_page

      results.hits = scope

      results
    end

    def stats(scope, params, &block)
      results = build_results_with_filters(params)

      scope = apply_filters(scope, results.search_params)

      scope = scope.reorder("") # reset order due to optional fulltext search

      block.call(scope, results) if block_given?

      results
    end

    private

    def apply_filters(scope, params)
      @filters.each do |filter|
        scope = filter.apply(scope, params)
      end

      scope
    end

    def apply_sort(scope, params)
      @sorts.each do |sort|
        scope = sort.apply(scope, params)
      end

      scope
    end

    # Filters only ever see permitted params, so unexpected shapes (e.g. a hash where
    # an array or scalar is expected) are dropped instead of reaching a query.
    def build_results_with_filters(params)
      results = Results.new
      permitted_params = @filters.each_with_object(@default_permitted_params.dup) do |filter, p|
        filter.add_permitted_params(p)
      end

      permitted_params << :sort
      permitted_params << :page

      results.search_params = ParamsNormalizer.call(params).permit(*permitted_params)

      @filters.each do |filter|
        filter.add_applied_filter(results)
      end

      @filters.each do |filter|
        filter.add_visible_filter(results)
      end

      @sorts.each do |sort|
        sort.add_sort(results)
      end

      results
    end
  end
end
