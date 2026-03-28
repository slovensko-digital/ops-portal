class AddResponsibleSubjectToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :responsible_subject, foreign_key: true, index: true
  end
end
