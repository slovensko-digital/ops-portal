# == Schema Information
#
# Table name: issues_updates
#
#  id              :bigint           not null, primary key
#  added_at        :datetime
#  email           :string
#  ip              :inet
#  name            :string
#  published       :boolean
#  text            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  author_id       :bigint
#  confirmed_by_id :bigint
#  issue_id        :bigint           not null
#
class Issues::Update < ApplicationRecord
  belongs_to :author, optional: true, class_name: 'User'
  belongs_to :confirmed_by, optional: true, class_name: 'User'
end
