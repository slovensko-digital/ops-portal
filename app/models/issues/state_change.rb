# == Schema Information
#
# Table name: issues_state_changes
#
#  id                  :bigint           not null, primary key
#  hidden              :boolean          default(FALSE), not null
#  triage_external_id  :integer
#  uuid                :uuid             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  activity_id         :bigint           not null
#  new_state_id        :bigint           not null
#  previous_state_id   :bigint
#
class Issues::StateChange < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :previous_state, optional: true, class_name: "Issues::State"
  belongs_to :new_state, class_name: "Issues::State"
  delegate :issue, to: :activity

  before_create -> { self.uuid = SecureRandom.uuid }

  def author_display_name
    "Systém"
  end

  def triage_activity_body
    "Zmena stavu z #{previous_state&.name || 'neznámeho stavu'} na #{new_state.name}"
  end

  def triage_visible?
    false
  end

  def visible?
    !hidden
  end
end
