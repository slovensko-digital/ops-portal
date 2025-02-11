# == Schema Information
#
# Table name: issues_comments
#
#  id           :bigint           not null, primary key
#  added_at     :datetime
#  author_email :string
#  author_name  :string
#  embed        :string
#  image        :string
#  ip           :inet
#  link         :string
#  published    :boolean
#  state        :boolean
#  text         :string
#  verification :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  activity_id  :bigint           not null
#  author_id    :bigint
#
class Issues::Comment < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity"

  has_many_attached :photos
end
