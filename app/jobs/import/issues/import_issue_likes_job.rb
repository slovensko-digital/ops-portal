module Import
  class Issues::ImportIssueLikesJob < ApplicationJob
    def perform(issue:)
      Legacy::Like.where(kategoria: "alerts").where(remoteid: issue.legacy_id).find_in_batches do |group|
        group.each do |legacy_record|
          user = Legacy::User.find_or_create_user(legacy_record.user)

          user.issue_likes.find_or_create_by!(
            issue: issue,
            created_at: legacy_record.timestamp
          ) if user
        end
      end
    end
  end
end
