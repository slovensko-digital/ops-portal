class Issues::Draft::FetchAddressDetailsJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(draft)
    details = fetch_osm_details(draft)

    address = details["address"]
    address = address.sort { |a, b| a["rank_address"] <=> b["rank_address"] } if address.is_a?(Array)
    administratives = address.select { it["type"] == "administrative" && it["isaddress"] }

    draft.address_house_number = address.find { _1["type"] == "house_number" }&.dig("localname")
    draft.address_street = address.find { _1["class"] == "highway" }&.dig("localname")
    draft.address_suburb = administratives.find { _1["admin_level"] == 10 }&.dig("localname")
    draft.address_municipality = administratives.find { _1["admin_level"] == 9 }&.dig("localname")
    draft.address_district = administratives.find { _1["admin_level"] == 8 }&.dig("localname")
    draft.address_city = administratives.find { _1["admin_level"] == 6 }&.dig("localname")
    draft.address_postcode = address.find { _1["type"] == "postcode" }&.dig("localname")
    draft.address_region = administratives.find { _1["admin_level"] == 4 }&.dig("localname")
    draft.address_country = address.find { _1["type"] == "country" }&.dig("localname")
    draft.address_country_code = address.find { _1["type"] == "country_code" }&.dig("localname")
    draft.address_data = details
    draft.save!
  end

  def fetch_osm_details(draft)
    conn = Faraday.new(
      url: "https://nominatim.openstreetmap.org",
      headers: {
        "content-type": "application/json",
        "User-Agent": "www.odkazprestarostu.sk",
        "Accept-Language": "sk"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
    end

    response = conn.get("/reverse", { lat: draft.latitude, lon: draft.longitude, format: :json })
    json = response.body

    osmtype = case json["osm_type"]
    when "way"
        "W"
    when "node"
        "N"
    when "relation"
        "R"
    else
        raise NotImplementedError, "Unknown osm_type: #{json["osm_type"]}"
    end
    response = conn.get("/details", { format: :json, osmtype: osmtype, osmid: json["osm_id"], addressdetails: 1 })
    response.body
  end
end
