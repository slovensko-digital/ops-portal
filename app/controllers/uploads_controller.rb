class UploadsController < ApplicationController
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/heic image/heif]

  def create
    new_blobs = params[:new_files].filter_map do |file|
      next unless file.content_type.in?(ALLOWED_CONTENT_TYPES)

      file = convert_to_supported_format(file)

      ActiveStorage::Blob.create_and_upload!(
        io: file,
        filename: file.original_filename,
        content_type: file.content_type,
      )
    end
    old_blobs = params.fetch(:blobs, []).map { |signed_id| ActiveStorage::Blob.find_signed(signed_id) }
    @blobs = old_blobs + new_blobs
    render partial: "form", locals: { blobs: @blobs, prefix: params[:uploads_prefix], wrapper_class: "pictures-wrapper" }
  end

  def rotate
    blob = ActiveStorage::Blob.find_signed(params[:id])
    blob.update!(rotation: (blob.rotation - 90) % 360)

    @blobs = params[:blobs].map { |signed_id| ActiveStorage::Blob.find_signed(signed_id) }
    render partial: "form", locals: { blobs: @blobs, prefix: params[:uploads_prefix], wrapper_class: "pictures-wrapper" }
  end

  def destroy
    @blobs = params[:blobs]
  end

  def convert_to_supported_format(file)
    return file unless convert_to_jpg?(file)

    convert_to_jpg(file)
  end

  def convert_to_jpg?(file)
    file.content_type.match?(%r{image/(heic|heif)}i)
  end

  def convert_to_jpg(file)
    tempfile = ImageProcessing::MiniMagick
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
