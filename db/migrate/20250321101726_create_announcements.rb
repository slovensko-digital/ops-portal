class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :text, null: false
      t.jsonb :raw, null: false, default: {}

      t.timestamps
    end
  end
end
