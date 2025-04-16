module Import
  class ImportAgentsJob < ApplicationJob
    include ImportMethods

    def perform
      Legacy::OldUser.where(rights: %w[A Ax]).find_each do |legacy_record|
        Legacy::User.create_agent_from_legacy_record(legacy_record)
      end
    end
  end
end
