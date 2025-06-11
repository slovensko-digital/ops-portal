# == Schema Information
#
# Table name: municipality_districts
#
#  id              :bigint           not null, primary key
#  aliases         :string           default([]), not null, is an Array
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

  def self.find_by_address(city:, municipality:, suburb:)
    result = MunicipalityDistrict.joins(:municipality)
      .where("municipalities.active = true")
      .where("? = ANY(municipalities.aliases)", city)
      .where("? = ANY(municipality_districts.aliases)", municipality)
      .first

    return result if result

    MunicipalityDistrict.joins(:municipality)
      .where("municipalities.active = true")
      .where("? = ANY(municipalities.aliases)", municipality)
      .where("? = ANY(municipality_districts.aliases)", suburb)
      .first
  end
end
