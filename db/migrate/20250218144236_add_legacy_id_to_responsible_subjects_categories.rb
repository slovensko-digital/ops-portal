class AddLegacyIdToResponsibleSubjectsCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :responsible_subjects_categories, :legacy_id, :integer
  end
end
