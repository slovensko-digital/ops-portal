# == Schema Information
#
# Table name: issues_comments
#
#  id                            :bigint           not null, primary key
#  author_email                  :string
#  author_name                   :string
#  hidden                        :boolean          default(FALSE)
#  imported_at                   :datetime
#  ip                            :inet
#  legacy_data                   :jsonb
#  text                          :string
#  type                          :string
#  uuid                          :uuid
#  verification                  :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  activity_id                   :bigint           not null
#  agent_author_id               :bigint
#  legacy_comment_id             :integer
#  legacy_communication_id       :integer
#  responsible_subject_author_id :bigint
#  triage_external_id            :integer
#  user_author_id                :bigint
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
