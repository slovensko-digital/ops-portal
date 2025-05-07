class AddPublicPraiseToIssues < ActiveRecord::Migration[8.0]
  def change
    add_column :issues, :praise_public, :boolean, default: false, null: false
  end
end
