module Import
  class Issues::ImportIssueCommunicationVotesJob < ApplicationJob
    def perform(communication:)
      Legacy::Like.where(kategoria: "emails").where(remoteid: communication.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          user = Legacy::User.find_or_create_user(legacy_record.user)
          communication.activity.votes.find_or_create_by!(
            vote: legacy_record.status,
            voter: user,
            created_at: legacy_record.timestamp
          ) if user
        end
      end
    end
  end
end
