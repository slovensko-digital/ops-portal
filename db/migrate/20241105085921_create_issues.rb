class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.string :title, null: false
      t.string :description, null: false
      t.string :author, null: false
      t.datetime :reported_at, null: false

      t.timestamps
    end
  end
end
