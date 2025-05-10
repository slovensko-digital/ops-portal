module Issues
  module DraftsHelper
    def stub_json_request(method, uri, body: nil, response:)
      stub = stub_request(method, uri)
      stub = stub.with(body: body) if body
      stub.to_return(
        body: file_fixture(response).read,
        headers: { "Content-Type" => "application/json" }
      )
    end

    def geolocate_latest_draft
      draft = Issues::Draft.last
      draft.address_data = {}
      draft.address_city = "Bratislava"
      draft.address_municipality = "Karlova Ves"
      draft.address_street = "Zohorská"
      draft.address_house_number = "3"
      draft.save!
    end
  end
end
