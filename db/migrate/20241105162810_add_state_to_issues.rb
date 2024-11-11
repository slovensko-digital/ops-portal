class AddStateToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :state, :string
  end
end
