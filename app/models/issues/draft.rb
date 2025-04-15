# == Schema Information
#
# Table name: issues_drafts
#
#  id                      :bigint           not null, primary key
#  address_city            :string
#  address_city_district   :string
#  address_country         :string
#  address_country_code    :string
#  address_county          :string
#  address_house_number    :string
#  address_neighbourhood   :string
#  address_postcode        :string
#  address_road            :string
#  address_state           :string
#  address_suburb          :string
#  address_town            :string
#  address_village         :string
#  anonymous               :boolean
#  checks                  :jsonb
#  description             :string
#  latitude                :float
#  latlon_from_exif        :boolean          default(FALSE)
#  longitude               :float
#  picked_suggestion_index :integer
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

  DEFAULT_STATE = Issues::State.find_by(name: "Čakajúci")

  def confirm
    issue = Issue.create!(
      title: title,
      description: description,
      author: author,
      anonymous: anonymous,
      latitude: latitude,
      longitude: longitude,
      address_state: address_state,
      address_county: address_county,
      address_city: address_city,
      address_city_district: address_city_district,
      address_suburb: address_suburb,
      address_village: address_village,
      address_town: address_town,
      address_street: address_road,
      address_house_number: address_house_number,
      address_postcode: address_postcode,
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      reported_at: created_at,
      state: Issues::State.find_by(name: "Čakajúci"),
      municipality: Municipality.find_by(name: address_city || address_village || address_town) || author.municipality || Municipality.first,
    )

    # TODO delete draft after success

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
      # TODO fix this - do not create categories from LLM probably
      self.category = Issues::Category.find_or_create_by!(name: category_suggestion)
      self.subcategory = self.category&.subcategories.find_by(name: subcategory_suggestion) || self.category.subcategories.create!(name: subcategory_suggestion)
      self.subtype = self.subcategory&.subtypes.find_by(name: subtype_suggestion) || self.subcategory.subtypes.create!(name: subtype_suggestion)
    end
    save(context: :suggestions_step)
  end

  private

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end
end
