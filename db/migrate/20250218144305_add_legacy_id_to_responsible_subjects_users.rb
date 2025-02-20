class AddLegacyIdToResponsibleSubjectsUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects_users, :legacy_id, :integer
    add_index :responsible_subjects_users, :legacy_id, unique: true
  end
end
