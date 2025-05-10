# == Schema Information
#
# Table name: issues_drafts
#
#  id                      :bigint           not null, primary key
#  address_city            :string
#  address_country         :string
#  address_country_code    :string
#  address_data            :jsonb
#  address_district        :string
#  address_house_number    :string
#  address_municipality    :string
#  address_postcode        :string
#  address_region          :string
#  address_street          :string
#  address_suburb          :string
#  anonymous               :boolean
#  checks                  :jsonb
#  description             :string
#  latitude                :float
#  latlon_from_exif        :boolean          default(FALSE)
#  longitude               :float
#  picked_suggestion_index :integer
#  submitted               :boolean          default(FALSE), not null
#  suggestions             :jsonb
#  title                   :string
#  zoom                    :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  author_id               :bigint           not null
#  category_id             :bigint
#  subcategory_id          :bigint
#  subtype_id              :bigint
#
class Issues::Draft < ApplicationRecord
  has_many_attached :photos, service: :draft_attachments do |photo|
    photo.variant :llm, resize_to_limit: [ 800, 600 ], preprocessed: true
    photo.variant :thumb, resize_to_limit: [ 320, 240 ], preprocessed: true
    photo.variant :square, resize_to_fill: [ 320, 320 ], preprocessed: true
  end

  belongs_to :category, class_name: "Issues::Category", optional: true
  belongs_to :subcategory, class_name: "Issues::Subcategory", optional: true
  belongs_to :subtype, class_name: "Issues::Subtype", optional: true
  belongs_to :author, class_name: "User", optional: false

  validates_presence_of :photos, on: :photos_step
  validates_presence_of :title, :description, on: :details_step
  validate :latlon_present, on: :geo_step
  validates_numericality_of :zoom, greater_than: 14, allow_nil: true, on: :geo_step
  validate :photos_allowed_content_type, on: :photos_step

  validate :municipality_supported, on: :checks_step
  validate :checks_passed, on: :checks_step

  def confirm
    # TODO handle error for unsupported areas
    municipality, municipality_district = Municipality.find_by_address(city: address_city, municipality: address_municipality, suburb: address_suburb)

    issue = Issue.create!(
      title: title,
      description: description,
      author: author,
      anonymous: anonymous,
      latitude: latitude,
      longitude: longitude,
      address_country: address_country,
      address_country_code: address_country_code,
      address_region: address_region,
      address_suburb: address_suburb,
      address_district: address_district,
      address_city: address_city,
      address_municipality: address_municipality,
      address_street: address_street,
      address_house_number: address_house_number,
      address_postcode: address_postcode,
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      state: Issues::State.find_by(name: "Čakajúci"),
      municipality: municipality,
      municipality_district: municipality_district,
    )

    # TODO delete draft after success
    self.update_attribute(:submitted, true)

    # TODO consider moving to background job
    photos.each do |photo|
      # move attachments between different storage services
      io = StringIO.new(photo.download)
      issue.photos.attach(
        io: io,
        filename: photo.filename,
        content_type: photo.content_type
      )
    end

    SyncIssueToTriageJob.perform_later(issue)
  end

  def needs_editing?
    checks.any? { |check| check["action"] == "back" }
  end

  def geo
    [ latitude, longitude ] if latitude.present? && longitude.present?
  end

  def load_geo_from_exif(photo)
    begin
      d = Exif::Data.new(photo.blob.download)
    rescue Exif::NotReadable
      return
    end

    gps = d[:gps]
    if gps && gps[:gps_latitude] && gps[:gps_longitude]
      self.latitude = gps_to_float(gps[:gps_latitude])
      self.longitude = gps_to_float(gps[:gps_longitude])
      self.latlon_from_exif = true
    end
  end

  def update_with_context(attributes, context)
    # TODO move to AR monkey-patch
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context)
    end
  end

  def pick_suggestion(suggestions_params)
    assign_attributes(suggestions_params)
    if picked_suggestion_index == -1
      self.title = self.description = nil
    else
      self.title, self.description, category_suggestion, subcategory_suggestion, subtype_suggestion = suggestions[picked_suggestion_index]&.values_at("title", "description", "category", "subcategory", "subtype")
      self.category = Issues::Category.find_by(name: category_suggestion)
      self.subcategory = self.category&.subcategories&.find_by(name: subcategory_suggestion)
      self.subtype = self.subcategory&.subtypes&.find_by(name: subtype_suggestion)
    end
    self.checks = nil # reset checks
    save(context: :suggestions_step)
  end

  def confirmable?
    checks.all? { |check| check["action"] == "confirm" }
  end

  private

  def photos_allowed_content_type
    errors.add(:photos, :invalid_content) if photos.any? { |file| !file.content_type.in?(UploadsController::ALLOWED_CONTENT_TYPES) }
  end

  def latlon_present
    errors.add(:base, :latlon_missing) if latitude.blank? || longitude.blank?
  end

  def checks_passed
    errors.add(:checks, :invalid) if checks.any?
  end

  def municipality_supported
    active_municipality = Municipality.find_by_address(city: address_city, municipality: address_municipality, suburb: address_suburb).first
    errors.add(:base, :municipality_supported_on_old_portal) if active_municipality && active_municipality.active_on_old_portal?
    errors.add(:base, :municipality_unsupported) unless active_municipality
  end

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end
end
