module ImportHelper
  def convert_timestamp_value(value)
    Time.at(value).to_datetime
  end

  def download_from_ops_portal(path)
    URI.parse("#{ENV.fetch("LEGACY_PORTAL_URL")}/#{path}").open
  end

  def generate_dummy_email(id)
    "#{id}@localhost.dev"
  end
end
