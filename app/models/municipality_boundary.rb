# == Schema Information
#
# Table name: municipality_boundaries
#
#  id                       :bigint           not null, primary key
#  municipality_district_id :bigint
#  municipality_id          :bigint
#  boundary                 :geometry(Geometr not null
#  boundary_kind            :string           default("municipality"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class MunicipalityBoundary < ApplicationRecord
  KINDS = %w[municipality district].freeze
  MATCHED_SQL = "(CASE municipality_boundaries.boundary_kind WHEN 'district' " \
                "THEN municipality_boundaries.municipality_district_id IS NOT NULL " \
                "ELSE municipality_boundaries.municipality_id IS NOT NULL END)".freeze

  belongs_to :municipality, optional: true
  belongs_to :municipality_district, optional: true

  scope :district_boundaries, -> { where(boundary_kind: "district") }
  scope :districts, -> { district_boundaries.where.not(municipality_district_id: nil) }
  scope :municipalities, -> { where(boundary_kind: "municipality").where.not(municipality_id: nil) }
  scope :unmatched_municipalities, -> { where(boundary_kind: "municipality", municipality_id: nil) }
  scope :unmatched_districts, -> { district_boundaries.where(municipality_district_id: nil) }

  scope :matched, -> { where(MATCHED_SQL) }
  scope :unmatched, -> { where.not(MATCHED_SQL) }

  scope :with_bounds, -> {
    select(:id, "ST_XMin(boundary) AS min_lon", "ST_YMin(boundary) AS min_lat", "ST_XMax(boundary) AS max_lon", "ST_YMax(boundary) AS max_lat")
  }

  # [[south, west], [north, east]], needs the with_bounds scope
  def bounds
    [ [ self[:min_lat], self[:min_lon] ], [ self[:max_lat], self[:max_lon] ] ]
  end

  def matched?
    boundary_kind == "district" ? municipality_district_id.present? : municipality_id.present?
  end

  scope :containing_point, ->(latitude, longitude) {
    where(
      "ST_Covers(boundary, ST_SetSRID(ST_MakePoint(?, ?), 4326))",
      longitude, latitude
    )
  }
end
