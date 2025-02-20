class AddLegacyIdToResponsibleSubjects < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects, :legacy_id, :integer
    add_index :responsible_subjects, :legacy_id, unique: true
  end
end
