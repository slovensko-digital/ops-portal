class AddExternalIdToResponsibleSubjects < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects, :external_id, :string
  end
end
