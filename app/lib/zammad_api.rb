class ZammadApi
  DEFAULT_GROUP = "Incoming"
  DEFAULT_ARTICLE_TYPE = "web"

  def initialize(url:, http_token:, handler: Faraday)
    @url = url
    @http_token = http_token
    @handler = handler
    @handler.options.timeout = 900_000
  end

  def check_import_mode!
    status, body = request(:get, "#{@url}settings", {}, header)

    raise "Unexpected status: #{status}" unless status == 200

    import_mode_on = body.select { |attribute| attribute["name"] == "import_mode" }.first["state_current"]["value"]

    raise "Import mode OFF" unless import_mode_on
  end

  private

  def header
    {
      "Authorization": "Token token=#{@http_token}"
    }
  end

  def request(method, path, *args)
    response = @handler.public_send(method, path, *args)
    structure = response.body.empty? ? nil : JSON.parse(response.body)
  rescue StandardError => error
    raise error.response if error.respond_to?(:response) && error.response
    raise error
  else
    [ response.status, structure ]
  end
end
