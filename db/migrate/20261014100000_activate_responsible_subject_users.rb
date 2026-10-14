class ActivateResponsibleSubjectUsers < ActiveRecord::Migration[8.1]
  def up
    User::ResponsibleSubject.where(active: nil).update_all(active: true)
  end

  def down
  end
end
