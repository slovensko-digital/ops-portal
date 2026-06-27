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
