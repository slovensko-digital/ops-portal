module ImportMethods
  extend ActiveSupport::Concern

  included do
    def convert_timestamp_value(value)
      Time.at(value).to_datetime
    end

    def download_from_ops_portal(path)
      URI.parse("#{ENV.fetch("LEGACY_PORTAL_URL")}/#{path}").open
    end
  end
end
