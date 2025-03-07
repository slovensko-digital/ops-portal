class AddStreetIdToIssues < ActiveRecord::Migration[8.0]
  def change
    add_reference :issues, :street, null: true, foreign_key: true
  end
end
