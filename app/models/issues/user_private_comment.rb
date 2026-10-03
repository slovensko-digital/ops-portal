# == Schema Information
#
# Table name: issues_comments
#
#  id                            :bigint           not null, primary key
#  activity_id                   :bigint           not null
#  agent_author_id               :bigint
#  legacy_comment_id             :integer
#  legacy_communication_id       :integer
#  responsible_subject_author_id :bigint
#  triage_external_id            :integer
#  user_author_id                :bigint
#  author_email                  :string
#  author_name                   :string
#  hidden                        :boolean          default(FALSE)
#  ip                            :inet
#  legacy_data                   :jsonb
#  text                          :string
#  type                          :string
#  uuid                          :uuid
#  verification                  :integer
#  imported_at                   :datetime
#  last_edited_at                :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#
class Issues::UserPrivateComment < Issues::UserComment
  validates :agent_author_id, absence: true
  validates :responsible_subject_author_id, absence: true

  def author
    user_author
  end

  def visible?
    false
  end

  def triage_visible?
    !hidden
  end
end
