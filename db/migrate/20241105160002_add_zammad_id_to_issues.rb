class AddZammadIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :zammad_id, :integer
  end
end
