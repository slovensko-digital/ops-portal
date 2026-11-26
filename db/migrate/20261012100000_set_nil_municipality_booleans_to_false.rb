class SetNilMunicipalityBooleansToFalse < ActiveRecord::Migration[8.1]
  class Municipality < ActiveRecord::Base
    self.table_name = "municipalities"
  end

  def up
    Municipality.where(active: nil).update_all(active: false)
    Municipality.where(has_municipality_districts: nil).update_all(has_municipality_districts: false)
    Municipality.where(archived: nil).update_all(archived: false)
  end

  def down
  end
end
