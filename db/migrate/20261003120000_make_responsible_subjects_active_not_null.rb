class MakeResponsibleSubjectsActiveNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_default :responsible_subjects, :active, from: nil, to: true
    change_column_null :responsible_subjects, :active, false
  end
end
