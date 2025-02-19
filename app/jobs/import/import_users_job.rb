module Import
  class ImportUsersJob < ApplicationJob
    include ImportHelper

    def perform
      Legacy::GenericModel.set_table_name("users")
      Legacy::GenericModel.find_in_batches do |group|
        group.each do |legacy_record|
          create_user_from_legacy_record(legacy_record)
        end
      end
    end
  end
end
