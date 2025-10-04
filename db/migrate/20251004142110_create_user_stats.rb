class CreateUserStats < ActiveRecord::Migration[8.0]
  def change
    create_table :user_stats do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.integer :issues_count, default: 0
      t.integer :comments_count, default: 0
      t.integer :verified_issues_count, default: 0

      t.decimal :issues_percentile, precision: 5, scale: 4, default: 0
      t.decimal :comments_percentile, precision: 5, scale: 4, default: 0
      t.decimal :verified_issues_percentile, precision: 5, scale: 4, default: 0

      t.timestamps
    end
  end
end
