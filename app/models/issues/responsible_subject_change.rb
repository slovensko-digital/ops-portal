# == Schema Information
#
# Table name: issues_responsible_subject_changes
#
#  id                            :bigint           not null, primary key
#  change_type                   :integer          not null
#  hidden                        :boolean          default(FALSE), not null
#  text                          :string
#  uuid                          :uuid             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  activity_id                   :bigint           not null
#  responsible_subject_author_id :bigint
#  responsible_subject_id        :bigint
#  triage_external_id            :integer
#  user_author_id                :bigint
#
class Issues::ResponsibleSubjectChange < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :user_author, optional: true, class_name: "User"
  belongs_to :responsible_subject_author, optional: true, class_name: "::ResponsibleSubject"
  belongs_to :responsible_subject, optional: true, class_name: "::ResponsibleSubject"
  delegate :issue, to: :activity

  include Issues::ActivityObjectAttachments

  validates :text, presence: true
  validates :responsible_subject, presence: true, if: :reassignment?
  validates :responsible_subject, comparison: { other_than: ->(rs) { rs.issue&.responsible_subject } }, if: -> { reassignment? && responsible_subject.present? }

  enum :change_type, { reassignment: 0, refer: 1 }, default: :reassignment

  before_create -> { self.uuid = SecureRandom.uuid }

  after_update :notify_subscribers, if: :saved_change_to_triage_external_id?

  def author
    responsible_subject_author
  end

  def author_display_name
    author&.subject_name || "Odpoveď zodpovedného subjektu"
  end

  def triage_activity_body
    text
  end

  def triage_visible?
    true
  end

  def visible?
    !hidden
  end

  def responsible_subject?
    true
  end

  private

  def notify_subscribers
    Notifications::PublishNewIssueCommentJob.perform_later(self)
  end
end
