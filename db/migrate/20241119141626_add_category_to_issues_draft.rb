class AddCategoryToIssuesDraft < ActiveRecord::Migration[8.0]
  def change
    add_column :issues_drafts, :category, :string
    add_column :issues_drafts, :subcategory, :string
    add_column :issues_drafts, :subtype, :string
  end
end
