module Issues
  module ActivityObjectAttachments
    extend ActiveSupport::Concern

    included do
      has_many_attached :attachments do |photo|
        photo.variant :thumb, resize_to_limit: [ 320, 240 ], preprocessed: true
      end
    end
  end
end
