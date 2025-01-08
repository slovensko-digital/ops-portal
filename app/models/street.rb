# == Schema Information
#
# Table name: streets
#
#  id                       :bigint           not null, primary key
#  latitude                 :float
#  longitude                :float
#  name                     :string
#  place_identifier         :string
#  tested                   :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  municipality_district_id :bigint           not null
#  municipality_id          :bigint           not null
#
class Street < ApplicationRecord
  belongs_to :municipality
  belongs_to :municipality_district
end
