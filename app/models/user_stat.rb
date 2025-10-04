# == Schema Information
#
# Table name: user_stats
#
#  id                         :bigint           not null, primary key
#  comments_count             :integer          default(0)
#  comments_percentile        :decimal(5, 4)    default(0.0)
#  issues_count               :integer          default(0)
#  issues_percentile          :decimal(5, 4)    default(0.0)
#  verified_issues_count      :integer          default(0)
#  verified_issues_percentile :decimal(5, 4)    default(0.0)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  user_id                    :bigint           not null
#
class UserStat < ApplicationRecord
  belongs_to :user

  after_create_commit do
    UserStats::RefreshCountsUserJob.perform_later(user)
  end

  def stale?
    updated_at < 24.hours.ago
  end
end
