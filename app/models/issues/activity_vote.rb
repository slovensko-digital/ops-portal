# == Schema Information
#
# Table name: issues_activity_votes
#
#  id          :bigint           not null, primary key
#  vote        :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  activity_id :bigint           not null
#  voter_id    :bigint           not null
#
class Issues::ActivityVote < ApplicationRecord
  belongs_to :activity
  belongs_to :voter, class_name: "User"

  after_commit { activity.reset_counters }
end
