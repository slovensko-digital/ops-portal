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
#  uuid               :uuid
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_id        :bigint           not null
#  author_id          :bigint
#  confirmed_by_id    :bigint
#  legacy_id          :integer
#  triage_external_id :integer
#
class Issues::Update < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :author, optional: true, class_name: "User"
  belongs_to :confirmed_by, optional: true, class_name: "User"

  include Issues::ActivityObjectAttachments

  before_create -> { self.uuid = SecureRandom.uuid }

  def author_display_name
    author.display_name
  end

  def triage_activity_body
    text
  end

  def triage_visible?
    true
  end

  def visible?
    true
  end

  def visible?
    published
  end
end
