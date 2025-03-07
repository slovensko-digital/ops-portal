class AddResponsibleSubjectIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_reference :issues, :responsible_subject, null: true, foreign_key: true
  end
end
