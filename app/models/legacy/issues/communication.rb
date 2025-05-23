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
#  uuid                                :uuid
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
class Legacy::Issues::Communication < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :agent_author, optional: true, class_name: "Legacy::Agent"
  belongs_to :responsible_subjects_user_author, optional: true, class_name: "ResponsibleSubjects::User"

  include ::Issues::ActivityObjectAttachments

  before_create -> { self.uuid = SecureRandom.uuid }

  def triage_activity_body
    message
  end

  def in_triage_as_internal?
    true
  end
end
