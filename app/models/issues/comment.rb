# == Schema Information
#
# Table name: issues_comments
#
#  id                 :bigint           not null, primary key
#  added_at           :datetime
#  author_email       :string
#  author_name        :string
#  embed              :string
#  image              :string
#  ip                 :inet
#  link               :string
#  published          :boolean
#  state              :boolean
#  text               :string
#  verification       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_id        :bigint           not null
#  author_id          :bigint
#  legacy_id          :integer
#  triage_external_id :integer
#
class Issues::Comment < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity"
  belongs_to :author, class_name: "User", optional: true

  has_many_attached :attachments

  def activity_body
    return "Zmazaný komentár: #{text}" unless published

    text
  end
end
