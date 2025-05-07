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
#  imported_at              :datetime
#  issue_type               :integer          default("issue")
#  last_synced_at           :datetime
#  latitude                 :float
#  legacy_data              :jsonb
#  likes_count              :integer          default(0), not null
#  longitude                :float
#  praise_public            :boolean          default(FALSE), not null
#  title                    :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  author_id                :bigint
#  category_id              :bigint
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
  include PgSearch::Model

  enum :issue_type, { issue: 1, question: 2, praise: 3 }, default: :issue
  # TODO add triage_draft_external_id - este premenovat

  belongs_to :author, class_name: "User", optional: true
  belongs_to :owner, class_name: "Legacy::Agent", optional: true # TODO drop after legacy import
  belongs_to :category, class_name: "Issues::Category", optional: true
  belongs_to :subcategory, class_name: "Issues::Subcategory", optional: true
  belongs_to :subtype, class_name: "Issues::Subtype", optional: true
  belongs_to :municipality, optional: true
  belongs_to :municipality_district, optional: true
  belongs_to :responsible_subject, optional: true
  belongs_to :state, class_name: "Issues::State", optional: true

  has_many :activities, class_name: "Issues::Activity", dependent: :destroy
  has_many :comment_activities, class_name: "Issues::CommentActivity", dependent: :destroy
  has_many :legacy_communication_activities, class_name: "Legacy::Issues::CommunicationActivity", dependent: :destroy
  has_many :update_activities, class_name: "Issues::UpdateActivity", dependent: :destroy
  has_many :likes, class_name: "IssueLike", dependent: :destroy

  has_many_attached :photos do |photo|
    photo.variant :normal, resize_to_fill: [ 680, 680 ], preprocessed: true
    photo.variant :small, resize_to_fill: [ 320, 320 ], preprocessed: true
    photo.variant :thumb, resize_to_fill: [ 160, 160 ], preprocessed: true
  end

  validates :triage_external_id, uniqueness: true, allow_nil: true
  validates :category_id, presence: true, unless: ->(issue) { issue.issue_type == "praise" }
  validates_presence_of :title, :description, unless: -> { imported_at }

  pg_search_scope :fulltext_search, against: [ :title, :description, :legacy_id ], ignoring: :accents
  scope :publicly_visible, -> { joins(:state).where.not(state: { key: %w[waiting rejected] }) }

  def votes
    # fake it
    @_votes ||= OpenStruct.new(count: legacy_data ? legacy_data["like_count"] : Random.rand(10))
  end

  def backoffice_owner
    ResponsibleSubjects::User.find_by(legacy_id: legacy_data["backoffice_owner_legacy_id"]) if legacy_data["backoffice_owner_legacy_id"]
  end

  def liked_by?(user)
    user.issue_likes.where(issue: self).exists?
  end

  def editable_by?(user)
    return false unless user == author
    return false unless editable?

    true
  end

  def public?
    !state.key.in? %w[waiting rejected]
  end

  def editable?
    state.key == "waiting"
  end

  def should_create_resolution_process?
    return false if resolution_external_id.present?

    # TODO: revise this logic
    return true if state.name == "Zaslaný zodpovednému" && responsible_subject.present?

    false
  end

  def self.within_distance_from_point(lat, lon, distance)
    where("ST_DWithin(ST_Point(issues.longitude, issues.latitude, 4326)::geography, ST_Point(?, ?, 4326)::geography, ?)", lon, lat, distance)
  end

  def self.order_by_distance_from_point(lat, lon)
    select_sql = sanitize_sql([ Arel.sql("issues.*, ST_Distance(ST_Point(issues.longitude, issues.latitude)::geography, ST_Point(:lon, :lat, 4326)::geography) as distance"), { lon: lon, lat: lat } ])
    order_sql = sanitize_sql_for_order([ Arel.sql("ST_Point(issues.longitude, issues.latitude, 4326)::geography <-> ST_Point(?, ?, 4326)::geography"), lon, lat ])

    select(select_sql).reorder(order_sql)
  end
end
