# A saved version of a prompt edited in the admin prompt playground, to get back to it later.
# Shared by all admins. Only the newest AUTO_KEEP automatic snapshots are kept.
module Ai
  class PromptSnapshot < ApplicationRecord
    self.table_name = "ai_prompt_snapshots"

    AUTO_KEEP = 50

    REASONS = {
      "manual" => "ručne",
      "cms_reload" => "pred načítaním z CMS",
      "revert" => "pred obnovením snapshotu",
      "auto" => "automaticky"
    }.freeze

    belongs_to :author, class_name: "User", optional: true

    attribute :prompt_name, default: Ai::IssueChecks::PROMPT_NAME

    validates :content, presence: true
    validates :reason, inclusion: { in: REASONS.keys }

    scope :for_prompt, ->(prompt_name) { where(prompt_name:).order(created_at: :desc, id: :desc) }

    # Creates the snapshot unless the latest snapshot of the prompt has the same content.
    # Returns the new snapshot, or nil when nothing was created.
    def self.take(content:, reason:, note: nil, author: nil, prompt_name: Ai::IssueChecks::PROMPT_NAME)
      return if for_prompt(prompt_name).pick(:content) == content

      snapshot = create!(prompt_name:, content:, reason:, note: note.presence, author:)
      prune_auto(prompt_name)
      snapshot
    end

    def self.prune_auto(prompt_name)
      where(id: for_prompt(prompt_name).where(reason: "auto").offset(AUTO_KEEP).select(:id)).delete_all
    end

    def reason_label
      REASONS.fetch(reason)
    end
  end
end
