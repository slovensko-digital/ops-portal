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
class Issues::UserComment < Issues::Comment
  validates :agent_author_id, absence: true
  validates :responsible_subject_author_id, absence: true

  def author
    user_author
  end
end
