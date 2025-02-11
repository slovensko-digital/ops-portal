# == Schema Information
#
# Table name: municipalities
#
#  id                         :bigint           not null, primary key
#  active                     :boolean
#  alias                      :string
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
#
class Municipality < ApplicationRecord
  belongs_to :district, optional: true
  has_many :municipality_districts
  has_many :streets

  enum :municipality_type, huge: 2, other: 1
  enum :category, regional_capital: 1, town: 2, village: 3 # TODO Pomenovanie ciselnych hodnot iba podla nasho usudku
end
