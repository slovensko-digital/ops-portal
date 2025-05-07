class AddResponsibleSubjectLastContactAtToIssue < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :responsible_subject_last_contact_at, :datetime
    add_index :issues, :responsible_subject_last_contact_at
  end
end
