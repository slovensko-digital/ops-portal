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

    def attachment_mimetype_by_name(name)
      case File.extname(name.to_s).downcase
      when ".pdf"
        "application/pdf"
      when ".xml"
        "application/xml"
      when ".zip"
        "application/x-zip-compressed"
      when ".txt"
        "text/plain"
      when ".doc"
        "application/msword"
      when ".docx"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      when ".jpg", ".jpeg"
        "image/jpeg"
      when ".png"
        "image/png"
      when ".tiff", ".tif"
        "image/tiff"
      else
        "application/octet-stream"
      end
    end
  end
end
