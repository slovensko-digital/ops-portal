class CreateIssuesComments < ActiveRecord::Migration[8.0]
  def change
    create_table :issues_comments do |t|
      t.references :activity, null: false, foreign_key: { to_table: :issues_activities }
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.string :author_name
      t.string :author_email
      t.datetime :added_at
      t.boolean :state # TODO toto nevieme co znamena, vacsina komentarov ma hodnotu 1, zopar je ale s 0
      t.boolean :published
      t.string :text
      t.string :link
      t.string :image
      t.string :embed
      t.inet :ip
      t.integer :verification

      t.timestamps
    end
  end
end
