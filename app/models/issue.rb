# == Schema Information
#
# Table name: issues
#
#  id                 :bigint           not null, primary key
#  anonymous          :boolean
#  description        :string           not null
#  last_synced_at     :datetime
#  latitude           :float
#  legacy_data        :jsonb
#  longitude          :float
#  reported_at        :datetime         not null
#  title              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  author_id          :bigint
#  category_id        :bigint
#  municipality_id    :bigint           not null
#  state_id           :bigint
#  triage_external_id :integer
#
class Issue < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :category, class_name: "Issues::Category", optional: true
  belongs_to :municipality
  belongs_to :state, class_name: "Issues::State", optional: true

  has_many :updates, class_name: "Issues::Update"
  has_many :comments, class_name: "Issues::Comment"
  has_many :communications, class_name: "Issues::Communication"

  has_many_attached :photos

  # validates :triage_external_id, uniqueness: true TODO treba doriesit, aka hodnota tu ma byt pri prvotnom importe, kedze sa vyzaduje unique

  after_create_commit :schedule_send_to_zammad

  def schedule_send_to_zammad
    SendNewIssueToTriageJob.perform_later self
  end
end
