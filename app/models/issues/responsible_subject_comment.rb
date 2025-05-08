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
class Issues::ResponsibleSubjectComment < Issues::Comment
  validates :agent_author_id, absence: true
  validates :user_author_id, absence: true

  def author
    responsible_subject_author
  end

  def author_display_name
    responsible_subject_author.name
  end

  def backoffice_author
    Legacy::User.find_or_create_responsible_subjects_user(legacy_data&.fetch("user_id"))
  end

  def triage_activity_body
    [ TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG, super ].join(" ")
  end

  def backoffice_activity_body
    text
  end

  def internal?
    false
  end

  def visible?
    !hidden
  end

  def triage_visible?
    visible?
  end

  def triage_activity_body
    [ TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG, super ].join(" ")
  end
end
