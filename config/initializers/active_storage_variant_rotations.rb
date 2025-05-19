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

  module ActiveStorage::Blob::Representable
    def variant(transformations)
      if variable?
        transformations[:rotate] = rotation if self.rotation
        variant_class.new(self, ActiveStorage::Variation.wrap(transformations).default_to(default_variant_transformations))
      else
        raise ActiveStorage::InvariableError, "Can't transform blob with ID=#{id} and content_type=#{content_type}"
      end
    end
  end
end
