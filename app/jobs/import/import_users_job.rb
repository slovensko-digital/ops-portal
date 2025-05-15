module Import
  class ImportUsersJob < ApplicationJob
    queue_with_priority 100

    include ImportMethods

    def perform
      Legacy::OldUser.where(rights: "U").find_each do |legacy_record|
        user = Legacy::User.create_user_from_legacy_record(legacy_record)

        begin
          user.avatar.attach(io: download_avatar_from_ops_portal(user.legacy_id), filename: "#{user.id}.jpg") unless user.avatar.attached?
        rescue OpenURI::HTTPError
          # Ignored
        end
      end
    end
  end
end
