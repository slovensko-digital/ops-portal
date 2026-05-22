# == Schema Information
#
# Table name: municipality_boundaries
#
#  id                       :bigint           not null, primary key
#  boundary                 :geometry(Geometr not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  municipality_district_id :bigint
#  municipality_id          :bigint           not null
#
class MunicipalityBoundary < ApplicationRecord
  belongs_to :municipality
  belongs_to :municipality_district, optional: true

  scope :districts, -> { where.not(municipality_district_id: nil) }
  scope :municipalities, -> { where(municipality_district_id: nil) }

  scope :containing_point, ->(latitude, longitude) {
    where(
      "ST_Covers(boundary, ST_SetSRID(ST_MakePoint(?, ?), 4326))",
      longitude, latitude
    )
  }
end
