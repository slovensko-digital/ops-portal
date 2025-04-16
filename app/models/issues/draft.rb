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
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  author_id               :bigint           not null
#  category_id             :bigint
#  subcategory_id          :bigint
#  subtype_id              :bigint
#
class Issues::Draft < ApplicationRecord
  has_many_attached :photos do |photo|
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

  validate :municipality_supported, on: :checks_step
  validate :checks_passed, on: :checks_step

  def confirm
    # TODO handle OSM aliases
    # TODO handle error for unsupported areas
    if address_city.present?
      municipality_district = MunicipalityDistrict.joins(:municipality).where(municipality: { name: address_city, active: true }, name: address_municipality).first
      municipality = municipality_district&.municipality
    else
      municipality_district = nil
      municipality = Municipality.active.find_by_name(address_municipality)
    end

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
      address_district: address_district,
      address_city: address_city,
      address_municipality: address_municipality,
      address_street: address_street,
      address_house_number: address_house_number,
      address_postcode: address_postcode,
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      reported_at: created_at,
      state: Issues::State.find_by(name: "Čakajúci"),
      municipality: municipality,
      municipality_district: municipality_district,
    )

    # TODO delete draft after success
    self.update_attribute(:submitted, true)

    photos.each do |photo|
      issue.photos.append photo
    end

    SyncIssueToTriageJob.perform_later(issue)
  end

  def schedule_calculate_suggestions
    ::Issues::Draft::GenerateSuggestionsJob.perform_later(self)
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

  private

  def checks_passed
    errors.add(:checks, :invalid) if checks.any?
  end

  private

  def municipality_supported
    if address_city.present?
      municipality_district = MunicipalityDistrict.joins(:municipality).where(municipality: { name: address_city, active: true }, name: address_municipality).first
      municipality = municipality_district&.municipality
    else
      municipality = Municipality.active.find_by_name(address_municipality)
    end
    errors.add(:base, :municipality_unsupported) unless municipality
  end

  private

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end
end
