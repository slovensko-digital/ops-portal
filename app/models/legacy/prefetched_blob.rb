# == Schema Information
#
# Table name: legacy_prefetched_blobs
#
#  id         :bigint           not null, primary key
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Legacy::PrefetchedBlob < ApplicationRecord
  has_one_attached :attachment

  def self.get(url, filename, variants: [])
    cached = find_by(url: url)
    if cached
      Rails.logger.debug "CACHE HIT #{url}"
      return cached.attachment.blob
    end

    Rails.logger.debug "Prefetching #{url}"
    blob = ActiveStorage::Blob.create_and_upload!(
      io: URI.parse(url).open,
      filename: filename
    )
    prefetched_blob = create!(url: url, attachment: blob)

    prefetched_blob.attachment.blob
  end
end
