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
class Issues::Activity < ApplicationRecord
  belongs_to :issue
  has_many :votes, class_name: "Issues::ActivityVote"

  def content
    "dummy content"
  end

  def liked_by?(user)
    votes.where(voter: user, vote: 1).exists?
  end

  def disliked_by?(user)
    votes.where(voter: user, vote: -1).exists?
  end

  def reset_counters
    update(
      likes_count: votes.where(vote: 1).count,
      dislikes_count: votes.where(vote: -1).count
    )
  end
end
