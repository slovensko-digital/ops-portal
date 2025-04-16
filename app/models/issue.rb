# == Schema Information
#
# Table name: issues
#
#  id                       :bigint           not null, primary key
#  address_city             :string
#  address_country          :string
#  address_country_code     :string
#  address_district         :string
#  address_house_number     :string
#  address_municipality     :string
#  address_postcode         :string
#  address_region           :string
#  address_street           :string
#  anonymous                :boolean
#  description              :string           not null
#  issue_type               :integer          default("issue")
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
#  municipality_id          :bigint
#  owner_id                 :bigint
#  resolution_external_id   :integer
#  responsible_subject_id   :bigint
#  state_id                 :bigint
#  subcategory_id           :bigint
#  subtype_id               :bigint
#  triage_external_id       :integer
#
class Issue < ApplicationRecord
  enum :issue_type, { issue: 1, question: 2, praise: 3 }, default: :issue
  # TODO add triage_draft_external_id - este premenovat

  belongs_to :author, class_name: "User"
  belongs_to :owner, class_name: "Legacy::Agent", optional: true # TODO drop after legacy import
  belongs_to :category, class_name: "Issues::Category"
  belongs_to :subcategory, class_name: "Issues::Subcategory", optional: true
  belongs_to :subtype, class_name: "Issues::Subtype", optional: true
  belongs_to :municipality, optional: true
  belongs_to :municipality_district, optional: true
  belongs_to :responsible_subject, optional: true
  belongs_to :state, class_name: "Issues::State", optional: true

  has_many :activities, class_name: "Issues::Activity", dependent: :destroy
  has_many :comment_activities, class_name: "Issues::CommentActivity", dependent: :destroy
  has_many :communication_activities, class_name: "Issues::CommunicationActivity", dependent: :destroy
  has_many :update_activities, class_name: "Issues::UpdateActivity", dependent: :destroy

  has_many_attached :photos do |photo|
    photo.variant :small, resize_to_limit: [ 800, 600 ], preprocessed: true
  end

  validates :triage_external_id, uniqueness: true, allow_nil: true

  def votes
    # fake it
    @_votes ||= OpenStruct.new(count: legacy_data ? legacy_data["like_count"] : Random.rand(10))
  end

  def should_create_resolution_process?
    return false if resolution_external_id.present?

    # TODO: revise this logic
    return true if state.name == "Zaslaný zodpovednému" && responsible_subject.present?

    false
  end
end
