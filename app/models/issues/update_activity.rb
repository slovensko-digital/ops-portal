# == Schema Information
#
# Table name: issues_activities
#
#  id             :bigint           not null, primary key
#  type           :string           not null
#  issue_id       :bigint           not null
#  dislikes_count :integer          default(0), not null
#  likes_count    :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Issues::UpdateActivity < Issues::Activity
  has_one :activity_object, class_name: "Issues::Update", foreign_key: :activity_id, dependent: :destroy
end
