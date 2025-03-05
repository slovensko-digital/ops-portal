class AddCategoriesToResponsibleSubjectsCategories < ActiveRecord::Migration[8.0]
  def change
    change_column_null :responsible_subjects_categories, :issues_category_id, true
    add_reference :responsible_subjects_categories, :issues_subcategory, null: true
    add_reference :responsible_subjects_categories, :issues_subtype, null: true
  end
end
