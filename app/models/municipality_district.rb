# == Schema Information
#
# Table name: municipality_districts
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(FALSE)
#  aliases         :string           default([]), not null, is an Array
#  archived        :boolean          default(FALSE)
#  description     :string
#  genitiv         :string
#  logo            :string
#  lokal           :string
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  legacy_id       :integer
#  municipality_id :bigint           not null
#
class MunicipalityDistrict < ApplicationRecord
  belongs_to :municipality
  has_many :streets, dependent: :nullify
  has_many :issues

  scope :archived, -> { where(archived: true) }
  scope :active, -> { where(active: true) }

  def self.find_by_address(city:, municipality:, suburb:)
    result = MunicipalityDistrict.joins(:municipality)
      .where("municipalities.active = true")
      .where("? = ANY(municipalities.aliases)", city)
      .where("? = ANY(municipality_districts.aliases)", municipality)
      .first

    result ||= MunicipalityDistrict.joins(:municipality)
      .where("municipalities.active = true")
      .where("? = ANY(municipalities.aliases)", municipality)
      .where("? = ANY(municipality_districts.aliases)", suburb)
      .first

    result ||= MunicipalityDistrict.joins(:municipality)
      .where("municipalities.active = true")
      .where("? = ANY(municipalities.aliases)", city)
      .where("? = ANY(municipality_districts.aliases)", suburb)
      .first

    result
  end
end
