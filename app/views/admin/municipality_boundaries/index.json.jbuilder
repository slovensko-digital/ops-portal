json.type "FeatureCollection"
json.features @boundaries do |boundary|
  json.type "Feature"
  json.geometry JSON.parse(boundary.geojson)

  json.properties do
    json.id boundary.id
    json.kind boundary.boundary_kind
    json.municipality_id boundary.municipality_id
    json.municipality_name boundary.municipality_name
    json.municipality_active boundary.municipality_active
    json.municipality_district_id boundary.municipality_district_id
    json.municipality_district_name boundary.municipality_district_name
    json.matched boundary.matched?
  end
end
