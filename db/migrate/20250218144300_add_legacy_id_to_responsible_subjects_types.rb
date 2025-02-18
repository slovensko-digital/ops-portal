class AddLegacyIdToResponsibleSubjectsTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects_types, :legacy_id, :integer
  end
end
