module ImportMethods
  extend ActiveSupport::Concern

  included do
    def convert_timestamp_value(value)
      Time.at(value).to_datetime
    end

    def download_attachables_from_ops_portal(paths)
      paths.map do |path|
        {
          io: download_from_ops_portal(path),
          filename: File.basename(path)
        }
      end
    end

    def download_from_ops_portal(path)
      URI.parse("#{ENV.fetch("LEGACY_PORTAL_URL")}/#{path}").open
    end

    def download_avatar_from_ops_portal(user_legacy_id)
      URI.parse("#{ENV.fetch("LEGACY_PORTAL_URL")}/public/avatar/#{user_legacy_id}.jpg").open
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
