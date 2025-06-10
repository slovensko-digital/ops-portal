class AddDeletedAtToResponsibleSubjects < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects, :deleted_at, :datetime
    add_index :responsible_subjects, :deleted_at
  end
end
