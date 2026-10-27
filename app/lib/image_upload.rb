require "vips"

# The one place that decides which uploaded files we accept as images and how we store them.
# UploadsController, draft photos and avatars go through it (models via ImageValidator),
# Triage attachments via `attachable`.
module ImageUpload
  CONTENT_TYPES = %w[image/jpeg image/png image/gif image/heic image/heif].freeze
  HEIC_CONTENT_TYPES = %w[image/heic image/heif].freeze

  # The content type is identified from the bytes like Active Storage does it, the type the
  # browser declared is not trusted. Bytes that are not recognised are identified by the
  # filename, so empty or random bytes named .png pass as image/png unless vips can read them.
  def self.image?(io, filename)
    content_type(io, filename).in?(CONTENT_TYPES) && readable?(io)
  end

  # Reads only the header, so it is cheap even for large photos.
  def self.readable?(io)
    if io.respond_to?(:path) && io.path
      Vips::Image.new_from_file(io.path)
    else
      Vips::Image.new_from_buffer(io.read, "")
    end
    true
  rescue Vips::Error
    false
  ensure
    io.rewind if io.respond_to?(:rewind)
  end

  # An uploaded file as we store it: HEIC/HEIF converted to JPEG, which browsers can show.
  # Anything else, including files that are not images, is returned unchanged for the caller to reject.
  def self.normalize(file)
    return file unless file.respond_to?(:original_filename)
    return file unless content_type(file, file.original_filename).in?(HEIC_CONTENT_TYPES) && readable?(file)

    ActionDispatch::Http::UploadedFile.new(
      tempfile: ImageProcessing::Vips.source(file).convert("jpg").call,
      filename: "#{::File.basename(file.original_filename, '.*')}.jpg",
      type: "image/jpeg"
    )
  end

  # Attachable for a file we must keep whatever it is (an operator's attachment from Triage).
  # One that looks like an image but vips can't read is stored as a plain file, so the portal
  # links to it instead of rendering a broken thumbnail.
  def self.attachable(io, filename)
    if ActiveStorage.variable_content_types.include?(content_type(io, filename)) && !readable?(io)
      { io: io, filename: filename, content_type: "application/octet-stream", identify: false }
    else
      { io: io, filename: filename }
    end
  end

  def self.content_type(io, filename)
    Marcel::MimeType.for(io, name: filename.to_s)
  ensure
    io.rewind
  end
end
