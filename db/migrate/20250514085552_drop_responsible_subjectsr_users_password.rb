class DropResponsibleSubjectsrUsersPassword < ActiveRecord::Migration[8.0]
  def change
    remove_column :responsible_subjects_users, :password, :string
  end
end
