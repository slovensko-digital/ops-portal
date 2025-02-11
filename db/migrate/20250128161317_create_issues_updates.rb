class CreateIssuesUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_updates do |t|
      t.references :activity, null: false, foreign_key: { to_table: :issues_activities }
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.string :name
      t.string :email
      t.string :text
      t.references :confirmed_by, null: true, foreign_key: { to_table: :users }
      t.datetime :added_at
      t.boolean :published # TODO toto iba odhadujeme, co status znamena
      t.inet :ip

      t.timestamps
    end
  end
end
