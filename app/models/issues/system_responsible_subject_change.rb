# == Schema Information
#
# Table name: issues_system_responsible_subject_changes
#
#  id                              :bigint           not null, primary key
#  hidden                          :boolean          default(FALSE), not null
#  uuid                            :uuid             not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  activity_id                     :bigint           not null
#  new_responsible_subject_id      :bigint
#  previous_responsible_subject_id :bigint
#
class Issues::SystemResponsibleSubjectChange < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :previous_responsible_subject, optional: true, class_name: "::ResponsibleSubject"
  belongs_to :new_responsible_subject, optional: true, class_name: "::ResponsibleSubject"

  delegate :issue, to: :activity

  before_create -> { self.uuid = SecureRandom.uuid }

  def triage_visible?
    false
  end

  def visible?
    !hidden
  end
end
