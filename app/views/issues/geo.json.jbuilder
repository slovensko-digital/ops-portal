json.type "FeatureCollection"
json.features @search_results.stats[:aggs_by_geohash] do |issue|
  json.type "Feature"

  json.properties do
    json.count issue.count
    json.nice_count number_to_human(issue.count, format: "%n%u", units: { thousand: "K" }, separator: ".", precision: 0)

    if issue.count > 1
      json.min_latitude issue.min_latitude
      json.max_latitude issue.max_latitude
      json.min_longitude issue.min_longitude
      json.max_longitude issue.max_longitude
    else
      json.title issue.title
      json.address format_issue_address(issue)
      json.created_at l(issue.created_at.to_date)
      json.url issue_url(issue)
    end
  end

  json.geometry do
    json.type "Point"
    json.coordinates [ issue.avg_longitude, issue.avg_latitude ]
  end
end
