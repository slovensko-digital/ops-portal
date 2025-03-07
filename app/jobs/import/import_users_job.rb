module Import
  class ImportUsersJob < ApplicationJob
    include ImportMethods

    def perform
      Legacy::GenericModel.set_table_name("users")
      Legacy::GenericModel.where(rights: "U").find_each do |legacy_record|
        Legacy::User.create_user_from_legacy_record(legacy_record)
      end
    end
  end
end
