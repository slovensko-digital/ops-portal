# == Schema Information
#
# Table name: issues
#
#  id                 :bigint           not null, primary key
#  address            :string
#  anonymous          :boolean
#  category           :string           not null
#  description        :string           not null
#  last_synced_at     :datetime
#  latitude           :float
#  longitude          :float
#  municipality       :string           not null
#  reported_at        :datetime         not null
#  state              :string
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  author_id          :bigint
#  triage_external_id :integer
#  user_id            :bigint
#
class Issue < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_many_attached :photos
  validates :triage_external_id, uniqueness: true

  after_create_commit :schedule_send_to_zammad

  def schedule_send_to_zammad
    SendNewIssueToTriageJob.perform_later self
  end
end
