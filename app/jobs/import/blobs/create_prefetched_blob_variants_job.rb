module Import
  class Blobs::CreatePrefetchedBlobVariantsJob < ApplicationJob
    queue_with_priority 100

    def perform(blob)
      blob.attachment.variant(:full).processed if blob.attachment.variable?
    end
  end
end
