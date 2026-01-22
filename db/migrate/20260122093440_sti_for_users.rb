class StiForUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :type, :string
    add_index :users, :type

    User.where.not(responsible_subject_id: nil).update_all(type: "User::ResponsibleSubject")
    User.where(responsible_subject_id: nil).update_all(type: "User::Citizen")
  end
end
