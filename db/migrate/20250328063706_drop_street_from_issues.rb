class DropStreetFromIssues < ActiveRecord::Migration[8.0]
  def change
    Issue.find_each do |issue|
      issue.legacy_data["street"] = issue.street&.name
      issue.legacy_data["street_legacy_id"] = issue.street&.legacy_id
      issue.save!
    end

    remove_reference :issues, :street, null: true, foreign_key: true
  end
end
