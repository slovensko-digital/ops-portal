class CreateIssueCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_categories do |t|
      t.string :category
      t.string :category_hu
      t.string :category_alias
      t.string :description
      t.string :description_hu
      t.boolean :catch_all, default: false
      t.references :parent, null: true, foreign_key: { to_table: :issue_categories }
      t.integer :weight

      t.timestamps
    end
  end
end
