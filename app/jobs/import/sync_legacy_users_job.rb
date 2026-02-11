module Import
  class SyncLegacyUsersJob < ApplicationJob
    include ImportMethods

    def perform
      last_legacy_user_id = ::User.where.not(legacy_id: nil).order(legacy_id: :desc).limit(1).pluck(:legacy_id).first

      Legacy::OldUser.where("id > ?", last_legacy_user_id).where(rights: "U").find_each do |legacy_record|
        user = Legacy::User.create_user_from_legacy_record(legacy_record)

        begin
          user.avatar.attach(io: download_avatar_from_ops_portal(user.legacy_id), filename: "#{user.id}.jpg") unless user.avatar.attached?
        rescue OpenURI::HTTPError => e
          raise e unless e.message == "404 Not Found"
        end
      end
    end
  end
end
