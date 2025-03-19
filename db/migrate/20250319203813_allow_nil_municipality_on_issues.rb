class AllowNilMunicipalityOnIssues < ActiveRecord::Migration[8.0]
  def change
    change_column_null :issues, :municipality_id, true
  end
end
