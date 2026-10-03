# == Schema Information
#
# Table name: issue_likes
#
#  id         :bigint           not null, primary key
#  issue_id   :bigint           not null
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class IssueLike < ApplicationRecord
  belongs_to :issue, counter_cache: :likes_count
  belongs_to :user
end
