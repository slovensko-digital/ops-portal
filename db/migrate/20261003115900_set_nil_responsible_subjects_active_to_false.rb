class SetNilResponsibleSubjectsActiveToFalse < ActiveRecord::Migration[8.1]
  class ResponsibleSubject < ActiveRecord::Base
    self.table_name = "responsible_subjects"
  end

  def up
    ResponsibleSubject.where(active: nil).update_all(active: false)
  end

  def down
  end
end
