class Issues::Draft::FetchAddressDetailsJob < ApplicationJob
  queue_as :default

  def perform(draft)
    details = fetch_osm_details(draft)

    address = details["address"]

    draft.address_house_number = address.find { _1["type"] == "house_number" }&.dig("localname")
    draft.address_street = address.find { _1["class"] == "highway" }&.dig("localname")
    draft.address_municipality = address.find { _1["type"] == "administrative" && _1["admin_level"] == 9 }&.dig("localname")
    draft.address_district = address.find { _1["type"] == "administrative" && _1["admin_level"] == 8 }&.dig("localname")
    draft.address_city = address.find { _1["type"] == "administrative" && _1["admin_level"] == 6 }&.dig("localname")
    draft.address_postcode = address.find { _1["type"] == "postcode" }&.dig("localname")
    draft.address_region = address.find { _1["type"] == "administrative" && _1["admin_level"] == 4 }&.dig("localname")
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

    # TODO what if not a node?
    # TODO handle errors
    osmtype = case json["osm_type"]
    when "way"
        "W"
    when "node"
        "N"
    else
        raise NotImplementedError, "Unknown osm_type: #{json["osm_type"]}"
    end
    response = conn.get("/details", { format: :json, osmtype: osmtype, osmid: json["osm_id"], addressdetails: 1 })
    response.body
  end
end
