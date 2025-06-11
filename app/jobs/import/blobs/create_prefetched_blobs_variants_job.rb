module Import
  class Blobs::CreatePrefetchedBlobsVariantsJob < ApplicationJob
    queue_with_priority 100

    def perform(conditions)
      Legacy::PrefetchedBlob.where(**conditions).find_each do |blob|
        Import::Blobs::CreatePrefetchedBlobVariantsJob.perform_later(blob) if blob.attachment.variable?
      end
    end
  end
end
