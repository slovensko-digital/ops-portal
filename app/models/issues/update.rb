# == Schema Information
#
# Table name: issues_updates
#
#  id                 :bigint           not null, primary key
#  email              :string
#  imported_at        :datetime
#  ip                 :inet
#  name               :string
#  published          :boolean
#  text               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_id        :bigint           not null
#  author_id          :bigint
#  confirmed_by_id    :bigint
#  legacy_id          :integer
#  triage_external_id :integer
#
class Issues::Update < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity"
  belongs_to :author, optional: true, class_name: "User"
  belongs_to :confirmed_by, optional: true, class_name: "User"

  has_many_attached :attachments

  def activity_body
    text
  end
end
