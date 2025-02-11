class CreateResponsibleSubjectsUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :responsible_subjects_user_roles do |t|
      t.string :slug
      t.string :name

      t.timestamps
    end
  end
end
