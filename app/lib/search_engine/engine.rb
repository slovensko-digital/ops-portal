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

    def map(scope, params)
      target_zoom = case params[:z].to_i
      when 1..5
          2
      when 6..7
          3
      when 8..10
          4
      when 11..12
      when 13..15
          6
      when 16..17
          7
      when 18
          18
      else
          4
      end

      scope = apply_filters(scope, params)
      scope = scope.reorder("") # reset order due to optional fulltext search

      issues_groups_scope = scope
        .select("avg(latitude) avg_latitude, avg(longitude) as avg_longitude,
                min(latitude) as min_latitude, max(latitude) as max_latitude,
                min(longitude) as min_longitude, max(longitude) as max_longitude,
                count(*) as count")
        .group("st_geohash(st_point(issues.longitude, issues.latitude, 4326), #{target_zoom})")
        .where("st_point(longitude, latitude, 4326) && st_makeenvelope(?, ?, ?, ?, 4326)", *params[:bbox].split(",").map(&:to_f))
        .reorder("").to_sql

      results = build_results_with_filters(params)

      lateral_join_scope = scope.unscoped
        .where("st_point(longitude, latitude, 4326) && st_point(issue_groups.avg_longitude, issue_groups.avg_latitude, 4326)")
        .limit(1)

      scope = scope.unscoped
        .select("i.*, issue_groups.*")
        .joins("LEFT JOIN LATERAL (#{lateral_join_scope.to_sql}) AS i ON true")
        .from("(#{issues_groups_scope}) issue_groups")

      results.stats = scope

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
