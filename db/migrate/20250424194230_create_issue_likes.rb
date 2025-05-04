class CreateIssueLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :issue_likes do |t|
      t.belongs_to :issue, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :issue_likes, [ :issue_id, :user_id ], unique: true
  end
end
