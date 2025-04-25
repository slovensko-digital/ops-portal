class DropIssuesReportedAt < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues, :reported_at, :datetime
  end
end
