class CreateIssuesCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_categories do |t|
      t.string :name
      t.string :name_hu
      t.string :alias
      t.string :description
      t.string :description_hu
      t.boolean :catch_all, default: false
      t.references :parent, null: true, foreign_key: { to_table: :issues_categories }
      t.integer :weight

      t.timestamps
    end
  end
end
