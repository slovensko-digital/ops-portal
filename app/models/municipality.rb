# == Schema Information
#
# Table name: municipalities
#
#  id                         :bigint           not null, primary key
#  active                     :boolean
#  active_on_old_portal       :boolean          default(FALSE), not null
#  aliases                    :string           default([]), not null, is an Array
#  category                   :integer
#  email                      :string
#  handled_by                 :integer
#  has_municipality_districts :boolean
#  languages                  :string
#  latitude                   :float
#  logo                       :string
#  longitude                  :float
#  municipality_type          :integer
#  name                       :string
#  population                 :integer
#  sub                        :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  district_id                :bigint
#  legacy_id                  :integer
#
class Municipality < ApplicationRecord
  belongs_to :district, optional: true
  has_many :municipality_districts
  has_many :streets

  scope :active, -> { where(active: true) }

  enum :municipality_type, huge: 2, other: 1
  enum :category, regional_capital: 1, town: 2, village: 3 # TODO Pomenovanie ciselnych hodnot iba podla nasho usudku

  def self.find_by_address(city:, municipality:, suburb:)
    municipality_district = MunicipalityDistrict.find_by_address(city: city, municipality: municipality, suburb: suburb)
    return [ municipality_district.municipality, municipality_district ] if municipality_district

    [ active.where("? = ANY(aliases)", municipality).first, nil ]
  end
end
