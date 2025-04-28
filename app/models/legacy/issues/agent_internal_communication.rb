
# == Schema Information
#
# Table name: legacy_issues_communications
#
#  id                                  :bigint           not null, primary key
#  confirmation_needed                 :boolean
#  email                               :string
#  from_responsible_subject            :boolean
#  imported_at                         :datetime
#  internal                            :boolean
#  ip                                  :inet
#  message                             :string
#  plain_message                       :string
#  signature                           :string
#  solution_rejected                   :boolean
#  solved                              :boolean
#  solved_by                           :string
#  solved_in                           :string
#  subject                             :string
#  text                                :string
#  type                                :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  activity_id                         :bigint           not null
#  admin_id                            :integer
#  agent_author_id                     :bigint
#  legacy_id                           :integer
#  person_id                           :integer
#  responsible_subjects_user_author_id :bigint
#  triage_external_id                  :integer
#  user_id                             :integer
#
class Legacy::Issues::AgentInternalCommunication < Legacy::Issues::Communication
  validates :responsible_subjects_user_author_id, absence: true

  def author
    agent_author
  end

  def triage_activity_body
    [ TriageZammadEnvironment::RESPONSIBLE_SUBJECT_ARTICLE_TAG, super ].join(" ")
  end
end
