# validates :photos, image: true
#
# Every attached file must have one of ImageUpload::CONTENT_TYPES, and the files attached in
# this save must be readable by vips. Stored blobs are not downloaded again.
class ImageValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if attachments(value).all? { |attachment| attachment.content_type.in?(ImageUpload::CONTENT_TYPES) } &&
      new_files(record, attribute).all? { |io| ImageUpload.readable?(io) }

    record.errors.add(attribute, options[:message] || :invalid)
  end

  private

  def attachments(value)
    Array.wrap(value.respond_to?(:attachments) ? value.attachments : value.attachment)
  end

  def new_files(record, attribute)
    change = record.attachment_changes[attribute.to_s]
    return [] unless change

    attachables = change.respond_to?(:attachables) ? change.attachables : change.attachable
    Array.wrap(attachables)
      .map { |attachable| attachable.is_a?(Hash) ? attachable[:io] : attachable }
      .select { |io| io.respond_to?(:read) }
  end
end
