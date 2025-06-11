class Import::UnsetMunicipalityDistrictsJob < ApplicationJob
  def perform(municipality:)
    ::Issue.where(municipality: municipality).update_all(municipality_district_id: nil)
    ::MunicipalityDistrict.where(municipality: municipality).destroy_all
  end
end
