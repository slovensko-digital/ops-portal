class AddLegacyIdToResponsibleSubjects < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects, :legacy_id, :integer
  end
end
