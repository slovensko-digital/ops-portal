# == Schema Information
#
# Table name: issues
#
#  id                                  :bigint           not null, primary key
#  address_city                        :string
#  address_country                     :string
#  address_country_code                :string
#  address_district                    :string
#  address_house_number                :string
#  address_municipality                :string
#  address_postcode                    :string
#  address_region                      :string
#  address_street                      :string
#  address_suburb                      :string
#  anonymous                           :boolean
#  comments_count                      :integer          default(0), not null
#  description                         :string           not null
#  fulltext_extra                      :string
#  imported_at                         :datetime
#  issue_type                          :integer          default("issue")
#  last_synced_at                      :datetime
#  latitude                            :float
#  legacy_data                         :jsonb
#  likes_count                         :integer          default(0), not null
#  longitude                           :float
#  public                              :boolean          default(FALSE), not null
#  responsible_subject_last_contact_at :datetime
#  title                               :string           not null
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  author_id                           :bigint
#  category_id                         :bigint
#  legacy_id                           :integer
#  municipality_district_id            :bigint
#  municipality_id                     :bigint
#  owner_id                            :bigint
#  resolution_external_id              :integer
#  responsible_subject_id              :bigint
#  state_id                            :bigint
#  subcategory_id                      :bigint
#  subtype_id                          :bigint
#  triage_external_id                  :integer
#
class Issue < ApplicationRecord
  include PgSearch::Faster

  enum :issue_type, { issue: 1, question: 2, praise: 3 }, default: :issue

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
  has_many :comments, class_name: "Issues::Comment", through: :comment_activities, source: :activity_object, dependent: :destroy
  has_many :likes, class_name: "IssueLike", dependent: :destroy
  has_many :subscriptions, class_name: "IssueSubscription", dependent: :destroy

  has_many_attached :photos do |photo|
    photo.variant :full, resize_to_limit: [ 1280, 960 ], preprocessed: true
    photo.variant :normal, resize_to_fill: [ 800, 800 ], preprocessed: true
    photo.variant :small, resize_to_fill: [ 360, 360 ], preprocessed: true
    photo.variant :thumb, resize_to_fill: [ 160, 160 ], preprocessed: true
  end

  validates :triage_external_id, uniqueness: true, allow_nil: true
  validates :category_id, presence: true, unless: ->(issue) { issue.issue_type == "praise" }
  validates_presence_of :title, :description, unless: -> { imported_at }

  scope :newest, -> { order(created_at: :desc) }
  scope :publicly_visible, -> { where.not(state_id: Issues::State.not_visible.pluck(:id)) }
  scope :currently_viewable_by, ->(user) do
    joins(:state).where("issues_states.key NOT IN(?) OR issues.author_id = ?", Issues::State::PRIVATE_KEYS, user.id)
  end

  before_save :recalculate_computed_fields
  after_update :notify_subscribers

  def visible_activity_objects
    activity_objects = activities.includes(:activity_object).order(created_at: :asc).map(&:activity_object).compact

    if triage_process?
      activity_objects.select(&:triage_visible?)
    else
      activity_objects.select(&:visible?)
    end
  end

  def triage_process?
    resolution_external_id.nil?
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

  def showing_comments_count?
    issue_type.in?(%w[issue question]) && comments_count.nonzero?
  end

  def should_create_resolution_process?
    return false if issue_type == "praise"
    return false if resolution_external_id.present?

    # TODO: revise this logic
    return true if state.name == "Zaslaný zodpovednému" && responsible_subject.present?

    false
  end

  def self.relevant_for(user)
    return where(municipality: user.municipality) if user&.municipality

    self
  end

  def self.within_distance_from_point(lat, lon, distance)
    where("ST_DWithin(ST_Point(issues.longitude, issues.latitude, 4326)::geography, ST_Point(?, ?, 4326)::geography, ?)", lon, lat, distance)
  end

  def self.order_by_distance_from_point(lat, lon)
    select_sql = sanitize_sql([ Arel.sql("issues.*, ST_Distance(ST_Point(issues.longitude, issues.latitude)::geography, ST_Point(:lon, :lat, 4326)::geography) as distance"), { lon: lon, lat: lat } ])
    order_sql = sanitize_sql_for_order([ Arel.sql("ST_Point(issues.longitude, issues.latitude, 4326)::geography <-> ST_Point(?, ?, 4326)::geography"), lon, lat ])

    select(select_sql).reorder(order_sql)
  end

  def recalculate_computed_fields
    self.responsible_subject_last_contact_at = Issues::ResponsibleSubjectComment
      .joins(activity: :issue)
      .where(issues: { id: id })
      .maximum(:created_at)

    self.comments_count = visible_activity_objects.count

    self.fulltext_extra = [
      category&.name, subcategory&.name, subtype&.name,
      address_city, address_municipality, address_street,
      state&.name
    ].compact.join(" ")
  end

  def reset_counters
    recalculate_computed_fields
    save
  end

  def notify_subscribers
    if issue_type == "praise"
      return unless saved_change_to_state_id?
      return unless saved_change_to_state_id.first == Issues::State.find_by(key: "waiting").id

      if state.key.in? %w[resolved resolved_private]
        Notifications::PublishIssueAcceptedJob.perform_later(self)
      elsif state.key == "rejected"
        Notifications::PublishIssueStateChangedJob.perform_later(self, state_id_change: saved_change_to_state_id)
      end
    elsif saved_change_to_resolution_external_id?
      Notifications::PublishIssueAcceptedJob.perform_later(self)
    elsif saved_change_to_state_id?
      Notifications::PublishIssueStateChangedJob.perform_later(self, state_id_change: saved_change_to_state_id)
    end
  end
end
