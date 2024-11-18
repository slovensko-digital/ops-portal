class AddChecksToDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :checks, :jsonb
  end
end
