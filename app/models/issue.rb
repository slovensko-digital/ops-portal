# == Schema Information
#
# Table name: issues
#
#  id                       :bigint           not null, primary key
#  anonymous                :boolean
#  description              :string           not null
#  last_synced_at           :datetime
#  latitude                 :float
#  legacy_data              :jsonb
#  longitude                :float
#  reported_at              :datetime         not null
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  author_id                :bigint
#  category_id              :bigint           not null
#  legacy_id                :integer
#  municipality_district_id :bigint
#  municipality_id          :bigint           not null
#  owner_id                 :bigint
#  responsible_subject_id   :bigint
#  state_id                 :bigint
#  street_id                :bigint
#  subcategory_id           :bigint
#  subtype_id               :bigint
#  triage_external_id       :integer
#
class Issue < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :owner, class_name: "Legacy::Agent", optional: true # TODO drop after legacy import
  belongs_to :category, class_name: "Issues::Category"
  belongs_to :subcategory, class_name: "Issues::Subcategory", optional: true
  belongs_to :subtype, class_name: "Issues::Subtype", optional: true
  belongs_to :municipality
  belongs_to :municipality_district, optional: true
  belongs_to :street, optional: true
  belongs_to :responsible_subject, optional: true
  belongs_to :state, class_name: "Issues::State", optional: true

  has_many :activities, class_name: "Issues::Activity", dependent: :destroy
  has_many :comment_activities, class_name: "Issues::CommentActivity", dependent: :destroy
  has_many :communication_activities, class_name: "Issues::CommunicationActivity", dependent: :destroy
  has_many :update_activities, class_name: "Issues::UpdateActivity", dependent: :destroy

  has_many_attached :photos

  validates :triage_external_id, uniqueness: true, allow_nil: true

  def schedule_send_to_zammad
    SendNewIssueToTriageJob.perform_later self
  end
end
