class AddLegacyIdToResponsibleSubjectsUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects_users, :legacy_id, :integer
  end
end
