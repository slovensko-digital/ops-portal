# == Schema Information
#
# Table name: issues_comments
#
#  id                            :bigint           not null, primary key
#  added_at                      :datetime
#  author_email                  :string
#  author_name                   :string
#  hidden                        :boolean          default(FALSE)
#  ip                            :inet
#  legacy_data                   :jsonb
#  text                          :string
#  type                          :string
#  verification                  :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  activity_id                   :bigint           not null
#  agent_author_id               :bigint
#  legacy_id                     :integer
#  responsible_subject_author_id :bigint
#  triage_external_id            :integer
#  user_author_id                :bigint
#
class Issues::AgentPrivateComment < Issues::Comment
  validates :user_author_id, absence: true
  validates :responsible_subject_author_id, absence: true

  def author
    agent_author
  end
end
