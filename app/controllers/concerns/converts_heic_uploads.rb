module ConvertsHeicUploads
  extend ActiveSupport::Concern

  private

  def convert_to_supported_format(file)
    return file unless convert_to_jpg?(file)

    convert_to_jpg(file)
  end

  def convert_to_jpg?(file)
    file.respond_to?(:content_type) && file.content_type.match?(%r{image/(heic|heif)}i)
  end

  def convert_to_jpg(file)
    tempfile = ImageProcessing::Vips
                 .source(file)
                 .convert("jpg")
                 .call

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: "#{::File.basename(file.original_filename, '.*')}.jpg",
      type: "image/jpeg"
    )
  end
end
