class UploadsController < ApplicationController
  def create
    new_blobs = params[:new_files].filter_map do |file|
      next unless ImageUpload.image?(file, file.original_filename)

      file = ImageUpload.normalize(file)
      ActiveStorage::Blob.create_and_upload!(io: file, filename: file.original_filename)
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
end
