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
class Issues::CommentActivity < Issues::Activity
  has_one :activity_object, class_name: "Issues::Comment", foreign_key: :activity_id

  def content
    activity_object.text
  end
end
