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
#  author_email                  :string
#  author_name                   :string
#  hidden                        :boolean          default(FALSE)
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
class Issues::AgentComment < Issues::Comment
  validates :user_author_id, absence: true
  validates :responsible_subject_author_id, absence: true

  after_create_commit :notify_subscribers, unless: -> { legacy_id }

  def author_display_name
    "Odkaz pre starostu"
  end

  def author
    agent_author
  end

  def triage_activity_body
    [ TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG, super ].join(" ")
  end

  def visible?
    !hidden
  end

  def triage_visible?
    visible?
  end

  def agent?
    true
  end
end
