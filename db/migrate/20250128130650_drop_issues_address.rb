class DropIssuesAddress < ActiveRecord::Migration[8.0]
  def change
    remove_column :issues, :address, :string
  end
end
