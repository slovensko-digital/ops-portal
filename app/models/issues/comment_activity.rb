# == Schema Information
#
# Table name: issues_activities
#
#  id             :bigint           not null, primary key
#  dislikes_count :integer          default(0), not null
#  likes_count    :integer          default(0), not null
#  type           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  issue_id       :bigint           not null
#
class Issues::CommentActivity < Issues::Activity
  has_one :activity_object, class_name: "Issues::Comment", foreign_key: :activity_id, dependent: :destroy

  def content
    activity_object.text
  end
end
