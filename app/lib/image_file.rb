require "vips"

# Checks that vips can read an image before we store it. A file is identified as an image
# by its filename when its bytes are not recognised, so empty or random bytes named .png
# would otherwise be stored as image/png and break every variant of it.
module ImageFile
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

  # True when every file attached to record's attachment name in this save can be read.
  # Blobs that are already stored are not checked.
  def self.new_attachments_readable?(record, name)
    change = record.attachment_changes[name.to_s]
    return true unless change

    attachables = change.respond_to?(:attachables) ? change.attachables : change.attachable
    Array.wrap(attachables).all? do |attachable|
      io = attachable.is_a?(Hash) ? attachable[:io] : attachable
      !io.respond_to?(:read) || readable?(io)
    end
  end
end
