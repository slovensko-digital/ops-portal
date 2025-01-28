# == Schema Information
#
# Table name: issues_drafts
#
#  id                      :bigint           not null, primary key
#  address_city            :string
#  address_city_district   :string
#  address_country         :string
#  address_country_code    :string
#  address_house_number    :string
#  address_neighbourhood   :string
#  address_postcode        :string
#  address_road            :string
#  address_state           :string
#  address_suburb          :string
#  address_town            :string
#  address_village         :string
#  anonymous               :boolean
#  author                  :string
#  category                :string
#  checks                  :jsonb
#  description             :string
#  latitude                :float
#  longitude               :float
#  picked_suggestion_index :integer
#  subcategory             :string
#  subtype                 :string
#  suggestions             :jsonb
#  title                   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
class Issues::Draft < ApplicationRecord
  has_many_attached :photos do |photo|
    photo.variant :llm, resize_to_limit: [ 800, 600 ], preprocessed: true
    photo.variant :thumb, resize_to_limit: [ 320, 240 ], preprocessed: true
  end

  validates_presence_of :photos, on: :photos_step
  validates_presence_of :title, :description, on: :details_step

  def confirm
    # TODO: choose real user
    user = User.find_or_create_by(
      email: ENV.fetch("DEFAULT_USER_EMAIL"),
      zammad_identifier: ENV.fetch("DEFAULT_USER_ZAMMAD_IDENTIFIER"),
      firstname: ENV.fetch("DEFAULT_USER_FIRSTNAME"),
      lastname: ENV.fetch("DEFAULT_USER_LASTNAME")
    )

    # TODO create issue and delete draft
    issue = Issue.create!(
      author: user,
      municipality: temp_get_municipality(),
      title: title,
      description: description,
      category: category,
      anonymous: anonymous,
      address: address_city,
      latitude: latitude,
      longitude: longitude,
      reported_at: created_at
    )

    photos.each do |photo|
      issue.photos.append photo
    end
  end

  def schedule_calculate_suggestions
    ::Issues::Draft::GenerateSuggestionsJob.perform_later(self)
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
      self.category = "1"
    else
      self.title, self.description, self.category, self.subcategory, self.subtype = suggestions[picked_suggestion_index]&.values_at("title", "description", "category", "subcategory", "subtype")
    end
    save(context: :suggestions_step)
  end

  private

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end

  # TODO: select real municipality
  def temp_get_municipality
    return "Hlohovec" unless address_city == "Bratislava"

    return "Bratislava::Staré Mesto" if address_city_district == "okres Bratislava I"
    return "Bratislava::Nové Mesto" if address_city_district == "okres Bratislava III"
    return "Bratislava::Karlova Ves" if address_city_district == "okres Bratislava IV"

    "Hlohvec"
  end
end
