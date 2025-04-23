module ImportMethods
  extend ActiveSupport::Concern

  included do
    def convert_timestamp_value(value)
      Time.at(value).to_datetime
    end

    def download_from_ops_portal(path)
      URI.parse("#{ENV.fetch("LEGACY_PORTAL_URL")}/#{path}").open
    end

    def attachment_persisted?(name:, content:, persisted_records:)
      blob = ActiveStorage::Blob.new(filename: name)
      blob.unfurl(content)

      persisted_records.blobs.where(checksum: blob.checksum).exists?
    end
  end
end
