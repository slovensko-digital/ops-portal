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
  end
end
