# == Schema Information
#
# Table name: issues_comments
#
#  id                            :bigint           not null, primary key
#  type                          :string
#  activity_id                   :bigint           not null
#  agent_author_id               :bigint
#  legacy_comment_id             :integer
#  legacy_communication_id       :integer
#  responsible_subject_author_id :bigint
#  triage_external_id            :integer
#  user_author_id                :bigint
#  ai_evaluation                 :jsonb            not null
#  author_email                  :string
#  author_name                   :string
#  hidden                        :boolean          default(FALSE), not null
#  ip                            :inet
#  legacy_data                   :jsonb
#  text                          :string
#  uuid                          :uuid
#  verification                  :integer
#  imported_at                   :datetime
#  last_edited_at                :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#
class Issues::UserComment < Issues::Comment
  validates :agent_author_id, absence: true
  validates :responsible_subject_author_id, absence: true
  validates :text, presence: true, if: -> { attachments.empty? }, unless: -> { legacy_id }

  include EditableWithinEditingWindow

  after_update :notify_subscribers, unless: -> { legacy_id }, if: :saved_change_to_triage_external_id?

  def author
    user_author
  end

  def triage_activity_body
    return "Automaticky skrytý komentár: #{text}" if auto_hidden?

    super
  end

  def auto_hidden?
    hidden && ai_evaluation.present? && Issues::ModerateCommentJob.hide?(ai_evaluation)
  end

  def hidden_reason
    ai_evaluation["reason"].presence if auto_hidden?
  end

  def visible?
    !hidden
  end

  def triage_visible?
    visible?
  end

  def editable_by?(user)
    return false unless user_author == user
    return false unless within_editing_window?

    true
  end
end
