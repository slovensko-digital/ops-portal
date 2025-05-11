module Issues
  module ActivityObjectAttachments
    extend ActiveSupport::Concern

    included do
      has_many_attached :attachments do |photo|
        photo.variant :full, resize_to_limit: [ 1280, 960 ], preprocessed: true
        photo.variant :small, resize_to_fill: [ 280, 280 ], preprocessed: true
        photo.variant :thumb, resize_to_fill: [ 160, 160 ], preprocessed: true
      end
    end
  end
end
