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
class Issues::Activity < ApplicationRecord
  belongs_to :issue

  def content
    "dummy content"
  end
end
