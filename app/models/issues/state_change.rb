# == Schema Information
#
# Table name: issues_state_changes
#
#  id                :bigint           not null, primary key
#  activity_id       :bigint           not null
#  new_state_id      :bigint           not null
#  previous_state_id :bigint
#  hidden            :boolean          default(FALSE), not null
#  uuid              :uuid             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Issues::StateChange < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :previous_state, optional: true, class_name: "Issues::State"
  belongs_to :new_state, class_name: "Issues::State"
  delegate :issue, to: :activity

  before_create -> { self.uuid = SecureRandom.uuid }

  # Supplement requests in triage (waiting <-> waiting_for_author) are not
  # timeline activity. They stay hidden while the issue is in triage and would
  # otherwise all pop up at once when the issue is accepted. The request itself
  # is visible as a comment and email.
  SUPPLEMENT_LOOP_KEYS = %w[waiting waiting_for_author].freeze

  def self.supplement_loop?(previous_state, new_state)
    return false unless previous_state && new_state

    SUPPLEMENT_LOOP_KEYS.include?(previous_state.key) && SUPPLEMENT_LOOP_KEYS.include?(new_state.key)
  end

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
