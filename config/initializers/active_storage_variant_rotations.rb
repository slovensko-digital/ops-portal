Rails.application.config.to_prepare do
  class ActiveStorage::Attachment < ActiveStorage::Record
    def variant(transformations)
      transformations = transformations_by_name(transformations)
      transformations[:rotate] = blob.rotation if blob.rotation
      blob.variant(transformations)
    end

    def representation(transformations)
      transformations = transformations_by_name(transformations)
      transformations[:rotate] = blob.rotation if blob.rotation
      blob.representation(transformations)
    end
  end
end
