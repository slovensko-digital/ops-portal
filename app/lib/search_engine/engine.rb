module SearchEngine
  class Engine
    def initialize(filters:, sorts: [], per_page: nil, default_permitted_params: [])
      @filters = filters
      @sorts = sorts
      @per_page = per_page
      @default_permitted_params = default_permitted_params
    end

    def search(scope, params)
      scope = apply_filters(scope, params)
      scope = apply_sort(scope, params)

      scope = scope.page(params[:page])
      scope = scope.per(@per_page) if @per_page

      results = build_results_with_filters(params)

      results.hits = scope

      results
    end

    def stats(scope, params)
      scope = apply_filters(scope, params)

      results = build_results_with_filters(params)

      scope = scope.reorder("") # reset order due to optional fulltext search
      results.stats = {
        by_state: scope.group("state").order("count_all DESC").async_count,
        by_category: scope.group("category").order("count_all DESC").async_count,
        by_responsible_subject: scope.group("responsible_subject").order("count_all DESC").async_count
      }

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

    def build_results_with_filters(params)
      results = Results.new
      permitted_params = @filters.each_with_object(@default_permitted_params) do |filter, p|
        filter.add_permitted_params(p)
      end

      permitted_params << :sort

      results.search_params = params.permit(*permitted_params)

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
