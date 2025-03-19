# == Schema Information
#
# Table name: issues_activities
#
#  id         :bigint           not null, primary key
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  issue_id   :bigint           not null
#
class Issues::CommunicationActivity < Issues::Activity
  has_one :activity_object, class_name: "Issues::Communication", foreign_key: :activity_id

  def import_to_triage_as_internal?
    true
  end
end
