module Import
  class SyncLegacyUsersJob < ApplicationJob
    def perform
      last_legacy_user_id = ::User.where.not(legacy_id: nil).last.legacy_id

      Legacy::OldUser.where("id > ?", last_legacy_user_id).where(rights: "U").find_each do |legacy_record|
        Legacy::User.create_user_from_legacy_record(legacy_record)
      end
    end
  end
end
