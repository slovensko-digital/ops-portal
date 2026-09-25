# == Schema Information
#
# Table name: issues_state_changes
#
#  id                 :bigint           not null, primary key
#  hidden             :boolean          default(FALSE), not null
#  uuid               :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_id        :bigint           not null
#  new_state_id       :bigint           not null
#  previous_state_id  :bigint
#  triage_external_id :integer
#
class Issues::StateChange < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :previous_state, optional: true, class_name: "Issues::State"
  belongs_to :new_state, class_name: "Issues::State"
  delegate :issue, to: :activity

  before_create -> { self.uuid = SecureRandom.uuid }

  def author_display_name
    "Odkaz pre starostu"
  end

  def triage_visible?
    false
  end

  def visible?
    !hidden
  end
end
