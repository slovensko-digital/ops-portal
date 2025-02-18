class AddLegacyIdToResponsibleSubjectsOrganizationUnits < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects_organization_units, :legacy_id, :integer
  end
end
