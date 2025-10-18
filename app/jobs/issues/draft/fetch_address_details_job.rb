class Issues::Draft::FetchAddressDetailsJob < ApplicationJob
  queue_as :default
  queue_with_priority ASAP

  def perform(draft)
    address_details = OsmClient.get_address_details(lat: draft.latitude, lon: draft.longitude)

    draft.update!(
      address_house_number: address_details.house_number,
      address_street: address_details.street,
      address_suburb: address_details.suburb,
      address_municipality: address_details.municipality,
      address_district: address_details.district,
      address_city: address_details.city,
      address_postcode: address_details.postcode,
      address_region: address_details.region,
      address_country: address_details.country,
      address_country_code: address_details.country_code,
      address_data: address_details.data
    )
  end
end
